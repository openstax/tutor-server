class Content::Routines::ImportExercises
  lev_routine outputs: {
                exercises: :_self,
                page_taggings: :_self
              },
              uses: [{ name: Content::Routines::FindOrCreateTags,
                       as: :find_or_create_tags },
                     { name: Content::Routines::TagResource, as: :tag }]

  protected
  # TODO: make this routine import only exercises from trusted authors
  #       or in some trusted list (for when OS Exercises is public)
  # page can be a Content::Models::Page or a block
  # that takes an OpenStax::Exercises::V1::Exercise
  # and returns a Content::Models::Page for that exercise
  def exec(ecosystem:, page:, query_hash:)
    set(exercises: [])

    wrappers = OpenStax::Exercises::V1.exercises(query_hash)['items']
    wrapper_urls = wrappers.uniq{ |wrapper| wrapper.url }

    wrapper_tag_hashes = wrappers.collect(&:tag_hashes).flatten.uniq { |h| h[:value] }
    tags = run(:find_or_create_tags, ecosystem: ecosystem, input: wrapper_tag_hashes).tags

    page_taggings = []

    wrappers.each do |wrapper|
      exercise_page = page.respond_to?(:call) ? page.call(wrapper) : page
      exercise = Content::Models::Exercise.new(url: wrapper.url,
                                               number: wrapper.number,
                                               version: wrapper.version,
                                               title: wrapper.title,
                                               content: wrapper.content,
                                               page: exercise_page)
      transfer_errors_from(exercise, { type: :verbatim }, true)

      relevant_tags = tags.select{ |tag| wrapper.tags.include?(tag.value) }
      exercise.exercise_tags = run(:tag, exercise, relevant_tags,
                                   tagging_class: Content::Models::ExerciseTag,
                                   save: false).taggings

      result.exercises << exercise

      lo_tags = relevant_tags.select{ |tag| tag.lo? }
      page_taggings += run(:tag, exercise_page, lo_tags,
                           tagging_class: Content::Models::PageTag,
                           save: false).taggings
    end

    set(page_taggings: page_taggings.uniq { |pt| [pt.content_page_id, pt.content_tag_id] })

    Content::Models::Exercise.import!(result.exercises, recursive: true)
    Content::Models::PageTag.import!(result.page_taggings)

    # Reset associations so they get reloaded the next time they are used
    result.page_taggings.map(&:page).uniq.each do |page|
      page.exercises.reset
      page.page_tags.reset
      page.tags.reset
    end

    result.exercises.each do |exercise|
      exercise.exercise_tags.reset
      exercise.tags.reset
    end

    if page.is_a?(Content::Models::Page)
      page.exercises.reset
      page.page_tags.reset
      page.tags.reset
    end
  end
end
