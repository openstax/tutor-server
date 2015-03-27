class Content::ImportBook

  lev_routine

  uses_routine Entity::CreateBook,
               as: :create_book,
               translations: { outputs: { type: :verbatim } }

  uses_routine Content::Routines::ImportBookPart,
               as: :import_book_part,
               translations: { outputs: { type: :verbatim } }

  protected

  # Imports and saves a Cnx::Book as an Entity::Book
  # Returns the Book object, Resource object and collection JSON as a hash
  def exec(cnx_book:)
    run(:create_book)

    run(:import_book_part, cnx_book_part: cnx_book.root_book_part,
                           book: outputs[:book])
    transfer_errors_from(outputs[:book_part], {type: :verbatim}, true)

    #
    # Send exercise and tag info to BigLearn
    #
    # First, build up local lists of the exercises and tags, then
    # send those lists all at once to one call each in the BL API.
    #
    # TODO this code below should probably be in Domain
    #

    exercise_data =
      Content::VisitBook[book: outputs[:book],
                              visitor_names: :exercises]

    biglearn_exercises = exercise_data.values.collect do |ed|
      tags = ed['topics'] + ed['tags']
      OpenStax::BigLearn::V1::Exercise.new(ed['uid'], *tags)
    end

    OpenStax::BigLearn::V1.add_exercises(biglearn_exercises)
  end

end
