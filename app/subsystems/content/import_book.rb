class Content::ImportBook

  lev_routine

  uses_routine Content::Routines::ImportBookPart, as: :import_book_part,
                                                  translations: { outputs: { type: :verbatim } }
  uses_routine Content::Routines::ImportExercises, as: :import_exercises,
                                                  translations: { outputs: { type: :verbatim } }
  uses_routine Content::Routines::UpdatePageContent, as: :update_page_content

  protected

  # Imports and saves a Cnx::Book as an Content::Models::Book
  # Returns the Book object, Resource object and collection JSON as a hash
  def exec(cnx_book:, ecosystem:)
    book = Content::Models::Book.new(url: cnx_book.url,
                                     uuid: cnx_book.uuid,
                                     version: cnx_book.version,
                                     title: cnx_book.title,
                                     content: cnx_book.root_book_part.contents,
                                     content_ecosystem_id: ecosystem.id)

    run(:import_book_part, cnx_book_part: cnx_book.root_book_part, book: book, save: false)

    Content::Models::Book.import! [book], recursive: true

    objective_page_tags = outputs[:page_taggings].select{ |pt| pt.tag.lo? || pt.tag.aplo? }
    query_hash = { tag: objective_page_tags.collect{ |pt| pt.tag.value } }
    page_block = ->(exercise_wrapper) {
      tags = exercise_wrapper.los + exercise_wrapper.aplos
      common_tags = objective_page_tags.select{ |pt| tags.include?(pt.tag.value) }
      pages = common_tags.collect{ |pt| pt.page }
      # Assume only one page for now
      pages.first
    }

    if objective_page_tags.empty?
      outputs[:exercises] = []
    else
      outputs[:exercises] = nil
      run(:import_exercises, page: page_block, query_hash: query_hash)
    end

    run(:update_page_content, pages: outputs[:pages])

    #
    # Send exercise and tag info to Biglearn
    #
    # First, build up local lists of the exercises and tags, then
    # send those lists all at once to one call each in the BL API.
    #
    # TODO this code below should probably be in Domain
    #

    biglearn_exercises = outputs[:exercises].collect do |ex|
      OpenStax::Biglearn::V1::Exercise.new(ex.url, *ex.exercise_tags.collect{ |ex| ex.tag.value })
    end
    OpenStax::Biglearn::V1.add_exercises(biglearn_exercises)
  end

end
