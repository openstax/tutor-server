class Content::ImportBook

  lev_routine

  uses_routine Content::Routines::ImportBookPart,
               as: :import_book_part,
               translations: { outputs: { type: :verbatim } }

  protected

  # Imports and saves a Cnx::Book as an Entity::Book
  # Returns the Book object, Resource object and collection JSON as a hash
  def exec(cnx_book:)
    outputs[:book] = Entity::Book.create!

    run(:import_book_part, cnx_book_part: cnx_book.root_book_part, book: outputs[:book])
    transfer_errors_from(outputs[:book_part], {type: :verbatim}, true)

    #
    # Send exercise and tag info to Biglearn
    #
    # First, build up local lists of the exercises and tags, then
    # send those lists all at once to one call each in the BL API.
    #
    # TODO this code below should probably be in Domain
    #

    puts "Adding exercises to biglearn"
    exercise_data = Content::VisitBook[book: outputs[:book], visitor_names: :exercises]

    biglearn_exercises = exercise_data.values.collect do |ed|
      tags = ed['los'] + ed['tags']
      OpenStax::Biglearn::V1::Exercise.new(ed['url'], *tags)
    end

    OpenStax::Biglearn::V1.add_exercises(biglearn_exercises)
  end

end
