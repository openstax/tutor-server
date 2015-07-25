class Content::Routines::ImportPage

  lev_routine express_output: :page

  uses_routine Content::Routines::CreatePage,
               as: :create_page,
               translations: { outputs: { type: :verbatim } }

  uses_routine Content::Routines::FindOrCreateTags,
               as: :find_or_create_tags,
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
  def exec(cnx_page:, book_part:, chapter_section: nil)
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
    run(:find_or_create_tags, input: cnx_page.tags)
    run(:tag, outputs[:page], outputs[:tags], tagging_class: Content::Models::PageTag)

    # Get Exercises from OSE that match the LO's
    los = outputs[:tags].select{ |tag| tag.lo? || tag.aplo? }.collect{ |tag| tag.value }
    run(:import_exercises, tag: los) unless los.empty?
  end

end
