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
  def exec(cnx_page:, chapter:, number: nil, book_location: nil, save: true, concept_coach_tag: nil)
    ecosystem = chapter.book.ecosystem

    outputs[:page] = Content::Models::Page.new(url: cnx_page.canonical_url,
                                               title: cnx_page.title,
                                               content: cnx_page.converted_content,
                                               chapter: chapter,
                                               number: number,
                                               book_location: book_location,
                                               uuid: cnx_page.uuid,
                                               version: cnx_page.version)
    outputs[:page].save if save
    transfer_errors_from(outputs[:page], {type: :verbatim}, true)
    chapter.pages << outputs[:page] unless chapter.nil?

    tags = cnx_page.tags

    if concept_coach_tag.present?
      chapter_tag = "#{concept_coach_tag}-ch#{"%02d" % book_location.first}"
      section_tag = "#{chapter_tag}-s#{"%02d" % book_location.last}"
      concept_coach_tags = [concept_coach_tag, chapter_tag, section_tag]
      tags += concept_coach_tags
    end

    # Tag the Page
    run(:find_or_create_tags, ecosystem: ecosystem, input: tags)
    run(:tag, outputs[:page], outputs[:tags], tagging_class: Content::Models::PageTag, save: save)

    outputs[:page].page_tags = outputs[:taggings]

    outputs[:exercises] = []

    return unless save

    # Get Exercises from OpenStax Exercises that match the LO's and AP LO's
    objective_tags = outputs[:tags].select{ |tag| tag.lo? || tag.aplo? }.collect{ |tag| tag.value }
    return if objective_tags.empty?

    run(:import_exercises, ecosystem: ecosystem, page: outputs[:page],
                           query_hash: {tag: objective_tags})
  end

end
