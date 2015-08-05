class Content::Routines::ImportPage

  lev_routine express_output: :page

  uses_routine Content::Routines::FindOrCreateTags,
               as: :find_or_create_tags,
               translations: { outputs: { type: :verbatim } }

  uses_routine Content::Routines::TagResource,
               as: :tag,
               translations: { outputs: { type: :verbatim } }

  uses_routine Content::Routines::ImportExercises,
               as: :import_exercises,
               translations: { outputs: { type: :verbatim } }

  protected

  # Imports and saves a Cnx::Page as a Content::Models::Page
  # into the given Content::Models::Chapter
  # Returns the Content::Models::Page object
  def exec(cnx_page:, chapter:, number: nil, book_location: nil, save: true)
    uuid, version = cnx_page.id.split('@')
    outputs[:page] = Content::Models::Page.new(url: cnx_page.url,
                                               title: cnx_page.title,
                                               content: cnx_page.converted_content,
                                               chapter: chapter,
                                               number: number,
                                               book_location: book_location,
                                               uuid: uuid,
                                               version: version)
    outputs[:page].save if save
    transfer_errors_from(outputs[:page], {type: :verbatim}, true)
    chapter.pages << outputs[:page] unless chapter.nil?

    # Tag the Page
    run(:find_or_create_tags, input: cnx_page.tags)
    run(:tag, outputs[:page], outputs[:tags], tagging_class: Content::Models::PageTag, save: save)

    outputs[:page].page_tags = outputs[:taggings]

    outputs[:exercises] = []

    return unless save

    # Get Exercises from OpenStax Exercises that match the LO's and AP LO's
    objective_tags = outputs[:tags].select{ |tag| tag.lo? || tag.aplo? }.collect{ |tag| tag.value }
    return if objective_tags.empty?

    run(:import_exercises, page: outputs[:page], query_hash: {tag: objective_tags})
  end

end
