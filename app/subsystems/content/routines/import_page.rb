class Content::Routines::ImportPage

  lev_routine

  uses_routine Content::Routines::CreatePage,
               as: :create_page,
               translations: { outputs: { type: :verbatim } }

  uses_routine Content::Routines::TagResource,
               as: :tag,
               translations: { outputs: { type: :verbatim } }

  uses_routine Content::Routines::ImportExercises,
               as: :import_exercises,
               translations: { outputs: { scope: :exercises } }

  protected

  # Imports and saves a Cnx::Page as a Content::Models::Page
  # into the given Content::Models::BookPart
  # Returns the Content::Models::Page object
  def exec(cnx_page:, book_part:, chapter_section:)
    uuid, version = cnx_page.id.split('@')
    run(:create_page, url: cnx_page.url,
                      title: cnx_page.title,
                      content: cnx_page.converted_content,
                      book_part: book_part,
                      chapter_section: chapter_section,
                      uuid: uuid,
                      version: version)
    book_part.pages << outputs[:page] unless book_part.nil?
    transfer_errors_from outputs[:page], {type: :verbatim}, true

    # Tag the Page
    run(:tag, outputs[:page], cnx_page.tags)

    # Get Exercises from OSE that match the LO's
    run(:import_exercises, tag: cnx_page.los + cnx_page.aplos) unless cnx_page.los.blank?
  end

end
