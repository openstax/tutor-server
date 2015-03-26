class Content::ImportPage

  lev_routine

  uses_routine Content::CreatePage,
               as: :create_page,
               translations: { outputs: { type: :verbatim } }

  uses_routine Content::TagResource,
               as: :tag,
               translations: { outputs: { type: :verbatim } }

  uses_routine Content::ImportExercises,
               as: :import_exercises,
               translations: { outputs: { scope: :exercises } }

  protected

  # Imports and saves a Cnx::Page as a Content::Page
  # into the given Content::BookPart
  # Returns the Content::Page object
  def exec(cnx_page:, book_part:)
    run(:create_page, url: cnx_page.url,
                      title: cnx_page.title,
                      content: cnx_page.converted_content,
                      book_part: book_part,
                      path: cnx_page.path)
    book_part.pages << outputs[:page] unless book_part.nil?
    transfer_errors_from outputs[:page], {type: :verbatim}, true

    # Tag Page with LO's
    run(:tag, outputs[:page], cnx_page.los, tag_type: :lo)

    # Get Exercises from OSE that match the LO's
    run(:import_exercises, tag: cnx_page.los)
  end

end
