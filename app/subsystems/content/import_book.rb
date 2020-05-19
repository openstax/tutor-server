class Content::ImportBook
  lev_routine

  uses_routine Content::Routines::ImportPage, as: :import_page
  uses_routine Content::Routines::ImportExercises, as: :import_exercises
  uses_routine Content::Routines::TransformAndCachePageContent, as: :transform_and_cache_content
  uses_routine Content::Routines::PopulateExercisePools, as: :populate_exercise_pools

  protected

  def import_pages!(book, book_part, book_indices = [], all_tags = nil)
    pages = book_part.parts.each_with_index.flat_map do |part, index|
      if part.is_a?(OpenStax::Cnx::V1::Page)
        outs = run(
          :import_page,
          book: book,
          book_indices: book_indices + [ index ],
          cnx_page: part,
          parent_book_part_uuid: book_part.uuid,
          save: false,
          all_tags: all_tags
        ).outputs

        all_tags = outs.all_tags

        outs.page
      else
        pages, all_tags = import_pages! book, part, book_indices + [ index ], all_tags
        pages
      end
    end

    [ pages, all_tags ]
  end

  def build_tree(book_part:, subtype:, ordered_pages:, page_index:)
    tree = []

    book_part.parts.each do |part|
      hash = { uuid: part.uuid, title: part.title, book_location: part.book_location }

      if part.is_a? OpenStax::Cnx::V1::Page
        hash[:type] = 'Page'
        page = ordered_pages[page_index]
        hash.merge!(
          page.attributes.symbolize_keys.slice :id, :version, :short_id, :tutor_uuid
        )
        Content::Models::Page::EXERCISE_ID_FIELDS.each do |field|
          hash[field] = page.public_send field
        end
        page_index += 1
      else
        hash[:type] = subtype
        hash[:tutor_uuid] = SecureRandom.uuid
        hash[:children], page_index = build_tree(
          book_part: part,
          subtype: 'Chapter',
          ordered_pages: ordered_pages,
          page_index: page_index
        )
        Content::Models::Page::EXERCISE_ID_FIELDS.each do |field|
          hash[field] = hash[:children].flat_map { |child| child[field] }.uniq
        end
      end

      tree << hash
    end

    [ tree, page_index ]
  end

  # Imports and saves a Cnx::Book as a Content::Models::Book
  # Returns the Book object, Resource object and collection JSON as a hash
  def exec(cnx_book:, ecosystem:, reading_processing_instructions: nil, exercise_uids: nil)
    root_book_part = cnx_book.root_book_part
    book = Content::Models::Book.new(
      url: cnx_book.canonical_url,
      uuid: cnx_book.uuid,
      short_id: cnx_book.short_id,
      version: cnx_book.version,
      title: cnx_book.title,
      baked_at: cnx_book.baked,
      is_collated: cnx_book.collated,
      content: root_book_part.contents,
      content_ecosystem_id: ecosystem.id,
      reading_processing_instructions: reading_processing_instructions.to_a.map(&:to_h),
      tree: {}
    )

    # Populate book.pages based on the cnx_book
    ordered_pages, all_tags = import_pages! book, root_book_part

    changed_tags = all_tags.filter(&:changed?)
    Content::Models::Tag.import changed_tags, validate: false, on_duplicate_key_update: {
      conflict_target: [ :value, :content_ecosystem_id ],
      columns: [ :name, :description, :tag_type ]
    }

    # To avoid weird behavior after import, we have to reset the imported association
    ecosystem.tags.reset

    # The book's tree is currently empty, but we need page ids and exercise uuids
    # before we can store the book tree, and the pages can only be saved if the book has an id
    Content::Models::Book.import [book], recursive: true, validate: false

    # Reset ordered_pages also to avoid weird behavior
    pages_by_id = book.pages.reset.preload(:tags).index_by(&:id)
    ordered_pages = ordered_pages.map { |page| pages_by_id[page.id] }

    import_page_map = {}
    ordered_pages.each do |page|
      page.tags.select(&:import?).each { |tag| import_page_map[tag.value] = page }
    end

    # If an exercise could go into multiple pages,
    # we always break ties by putting it in the page that appears last in the book
    page_block = ->(exercise_wrapper) do
      pages = exercise_wrapper.import_tags.map { |tag| import_page_map[tag] }.compact.uniq
      pages.max_by(&:book_location)
    end

    query_hash = if exercise_uids.nil?
      # Exercises not in manifest
      { tag: import_page_map.keys }
    else
      # Exercises in manifest
      { uid: exercise_uids }
    end

    run(
      :import_exercises,
      ecosystem: ecosystem, page: page_block, query_hash: query_hash, all_tags: all_tags
    )

    ordered_pages = run(
      :populate_exercise_pools, book: book, pages: ordered_pages, save: false
    ).outputs.pages

    # Now that we have page ids and exercise uuids, we can go back and store the book tree
    book.tree = {
      type: 'Book',
      title: book.title,
      book_location: [],
      id: book.id,
      uuid: book.uuid,
      version: book.version,
      short_id: book.short_id,
      tutor_uuid: book.tutor_uuid
    }
    subtype = root_book_part.parts.any? do |part|
      part.is_a?(OpenStax::Cnx::V1::BookPart) && part.parts.any? do |subpart|
        subpart.is_a?(OpenStax::Cnx::V1::BookPart)
      end
    end ? 'Unit' : 'Chapter'
    book.tree[:children], _ = build_tree(
      book_part: root_book_part, subtype: subtype, ordered_pages: ordered_pages, page_index: 0
    )
    Content::Models::Page::EXERCISE_ID_FIELDS.each do |field|
      book.tree[field] = book.tree[:children].flat_map { |child| child[field] }.uniq
    end
    book.save!

    # Transform links to point to the Tutor book etc
    ordered_pages = run(
      :transform_and_cache_content, book: book, pages: ordered_pages
    ).outputs.pages

    outputs.book = book
    outputs.pages = ordered_pages

    # Send ecosystem information to Biglearn
    OpenStax::Biglearn::Api.create_ecosystem(ecosystem: ecosystem)
  end
end
