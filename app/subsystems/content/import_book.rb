class Content::ImportBook
  lev_routine

  uses_routine Content::Routines::ImportPage, as: :import_page
  uses_routine Content::Routines::ImportExercises, as: :import_exercises
  uses_routine Content::Routines::TransformAndCachePageContent, as: :transform_and_cache_content
  uses_routine Content::Routines::PopulateExercisePools, as: :populate_exercise_pools

  protected

  def import_pages!(book, book_part)
    book_part.parts.flat_map do |part|
      if part.is_a?(OpenStax::Cnx::V1::Page)
        outs = run(:import_page, book: book, cnx_page: part, save: false).outputs
        outputs.page_taggings = (outputs.page_taggings || []) + outs.taggings
        outs.page
      else
        import_pages! book, part
      end
    end
  end

  def build_tree(book_part:, subtype:, ordered_pages:, page_index:)
    tree = []

    book_part.parts.each do |part|
      hash = { title: part.title, book_location: part.book_location }

      if part.is_a? OpenStax::Cnx::V1::Page
        hash[:type] = 'Page'
        page = ordered_pages[page_index]
        hash.merge!(
          page.attributes.symbolize_keys.slice :id, :uuid, :version, :short_id, :tutor_uuid
        )
        Content::Models::Page.pool_types.each do |pool_type|
          pool_method_name = "#{pool_type}_exercise_ids".to_sym
          hash[pool_method_name] = page.public_send pool_method_name
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
        Content::Models::Page.pool_types.each do |pool_type|
          pool_method_name = "#{pool_type}_exercise_ids".to_sym
          hash[pool_method_name] = hash[:children].flat_map { |child| child[pool_method_name] }.uniq
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
    ordered_pages = import_pages! book, root_book_part

    # The book's tree is currently empty, but we need page ids and exercise uuids
    # before we can store the book tree, and the pages can only be saved if the book has an id
    Content::Models::Book.import [book], recursive: true, validate: false

    import_page_tags = outputs.page_taggings.filter { |pt| pt.tag.import? }

    pages_by_id = ordered_pages.index_by(&:id)

    import_page_map = {}
    import_page_tags.each do |page_tag|
      import_page_map[page_tag.tag.value] = pages_by_id[page_tag.content_page_id]
    end

    outputs.exercises = []
    imported_exercise_numbers = Set.new

    # If an exercise could go into multiple pages,
    # we always break ties by putting it in the page that appears last in the book
    page_block = ->(exercise_wrapper) do
      tags = exercise_wrapper.import_tags
      pages = tags.map { |tag| import_page_map[tag] }.compact.uniq
      pages.max_by(&:book_location)
    end

    query_hash = if exercise_uids.nil?
      # Exercises not in manifest
      { tag: import_page_tags.map { |pt| pt.tag.value } }
    else
      # Exercises in manifest
      { uid: exercise_uids }
    end

    run :import_exercises, ecosystem: ecosystem, page: page_block, query_hash: query_hash

    run :populate_exercise_pools, book: book, pages: ordered_pages

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
    Content::Models::Page.pool_types.each do |pool_type|
      pool_method_name = "#{pool_type}_exercise_ids".to_sym
      book.tree[pool_method_name] = book.tree[:children].flat_map do |child|
        child[pool_method_name]
      end.uniq
    end
    book.save!

    # Transform links to point to the Tutor book etc
    run :transform_and_cache_content, book: book

    outputs.book = book
    outputs.pages = ordered_pages

    # Send ecosystem information to Biglearn
    OpenStax::Biglearn::Api.create_ecosystem(ecosystem: ecosystem)
  end
end
