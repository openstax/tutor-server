class Content::Api::ImportPage

  lev_routine

  uses_routine Content::Api::CreatePage,
               as: :create_page,
               translations: { outputs: { type: :verbatim } }

  uses_routine Content::Api::TagResourceWithTopics,
               as: :add_lo,
               translations: { outputs: { type: :verbatim } }

  uses_routine Content::Api::ImportExercises,
               as: :import_exercises,
               translations: { outputs: { scope: :exercises } }

  protected

  # Imports and saves a Cnx::Page as a Content::Models::Page
  # into the given Content::Models::BookPart
  # Returns the Content::Models::Page object
  def exec(cnx_page:, book_part:)
    run(:create_page, url: cnx_page.url,
                      title: cnx_page.title,
                      content: cnx_page.converted_content,
                      book_part: book_part,
                      path: cnx_page.path)
    book_part.pages << outputs[:page] unless book_part.nil?
    transfer_errors_from outputs[:page], {type: :verbatim}, true

    # Tag Page with LO's
    run(:add_lo, outputs[:page], cnx_page.los)

    # Get Exercises from OSE that match the LO's
    run(:import_exercises, tag: cnx_page.los)
  end

end
