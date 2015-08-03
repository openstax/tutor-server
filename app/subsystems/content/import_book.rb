class Content::ImportBook

  lev_routine

  uses_routine Content::Routines::ImportBookPart,
               as: :import_book_part,
               translations: { outputs: { type: :verbatim } }

  uses_routine Content::Routines::UpdatePageContent,
               as: :update_page_content

  uses_routine Content::Routines::VisitBook, as: :visit_book

  protected

  # Imports and saves a Cnx::Book as an Content::Models::Book
  # Returns the Book object, Resource object and collection JSON as a hash
  def exec(cnx_book:, ecosystem:)
    outputs[:book] = Content::Models::Book.create!(ecosystem_ecosystem_id: ecosystem.id)

    run(:import_book_part, cnx_book_part: cnx_book.root_book_part,
                           book: outputs[:book],
                           book_url: cnx_book.url,
                           uuid: cnx_book.uuid,
                           version: cnx_book.version)
    transfer_errors_from(outputs[:book_part], {type: :verbatim}, true)

    run(:update_page_content, book_part: outputs[:book_part])

    #
    # Send exercise and tag info to Biglearn
    #
    # First, build up local lists of the exercises and tags, then
    # send those lists all at once to one call each in the BL API.
    #
    # TODO this code below should probably be in Domain
    #

    exercise_data = run(:visit_book, book: outputs[:book], visitor_names: :exercise)
                      .outputs.visit_book

    biglearn_exercises = exercise_data.values.collect do |ed|
      tags = ed['los'] + ed['tags']
      OpenStax::Biglearn::V1::Exercise.new(ed['url'], *tags)
    end

    OpenStax::Biglearn::V1.add_exercises(biglearn_exercises)
  end

end
