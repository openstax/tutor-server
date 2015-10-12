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
  def exec(cnx_page:, chapter:, number: nil, book_location: nil, save: true, concept_coach_str: nil)
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

    if concept_coach_str.present?
      chapter_str = "#{concept_coach_str}-ch#{"%02d" % book_location.first}"
      section_str = "#{chapter_str}-s#{"%02d" % book_location.last}"
      tags << {
        value: section_str,
        type: :cc
      }
    end

    # Tag the Page
    run(:find_or_create_tags, ecosystem: ecosystem, input: tags)
    run(:tag, outputs[:page], outputs[:tags], tagging_class: Content::Models::PageTag, save: save)

    outputs[:page].page_tags = outputs[:taggings]

    outputs[:exercises] = []

    return unless save

    # Get Exercises from OpenStax Exercises that match the LO's or AP LO's, plus CC tags
    objective_tags = outputs[:tags].select do |tag|
      tag.lo? || tag.aplo? || tag.cc?
    end.collect{ |tag| tag.value }

    return if objective_tags.empty?

    run(:import_exercises, ecosystem: ecosystem, page: outputs[:page],
                           query_hash: {tag: objective_tags})
  end

end
