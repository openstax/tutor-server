class Content::Routines::ImportExercises

  lev_routine

  uses_routine Content::Routines::FindOrCreateTags, as: :find_or_create_tags
  uses_routine Content::Routines::TagResource, as: :tag

  protected

  # TODO: make this routine import only exercises from trusted authors
  #       or in some trusted list (for when OS Exercises is public)
  # page can be a Content::Models::Page or a block
  # that takes an OpenStax::Exercises::V1::Exercise
  # and returns a Content::Models::Page for that exercise
  def exec(ecosystem:, page:, query_hash:)
    outputs[:exercises] = []
    outputs[:page_taggings] = []

    wrappers = OpenStax::Exercises::V1.exercises(query_hash)['items']
    wrapper_urls = wrappers.uniq{ |wrapper| wrapper.url }

    wrapper_tag_hashes = wrappers.flat_map{ |wrapper| wrapper.tag_hashes }
                                 .uniq{ |hash| hash[:value] }
    tags = run(:find_or_create_tags, ecosystem: ecosystem, input: wrapper_tag_hashes).outputs.tags

    page_taggings = []
    wrappers.each do |wrapper|
      # Don't import multipart questions for now
      next if wrapper.is_multipart?

      exercise_page = page.respond_to?(:call) ? page.call(wrapper) : page
      exercise = Content::Models::Exercise.new(url: wrapper.url,
                                               number: wrapper.number,
                                               version: wrapper.version,
                                               title: wrapper.title,
                                               content: wrapper.content,
                                               page: exercise_page)
      transfer_errors_from(exercise, {type: :verbatim}, true)

      relevant_tags = tags.select{ |tag| wrapper.tags.include?(tag.value) }
      exercise.exercise_tags = run(:tag, exercise, relevant_tags,
                                   tagging_class: Content::Models::ExerciseTag,
                                   save: false).outputs.taggings

      outputs[:exercises] << exercise

      # Transfer LO and APLO tags to the page
      lo_tags = relevant_tags.select{ |tag| tag.lo? || tag.aplo? }
      page_taggings += run(:tag, exercise_page, lo_tags,
                           tagging_class: Content::Models::PageTag,
                           save: false).outputs.taggings
    end

    outputs[:page_taggings] = page_taggings.uniq{ |pt| [pt.content_page_id, pt.content_tag_id] }

    Content::Models::Exercise.import! outputs[:exercises], recursive: true
    Content::Models::PageTag.import! outputs[:page_taggings]

    # Reset associations so they get reloaded the next time they are used
    outputs[:page_taggings].map(&:page).uniq.each do |page|
      page.exercises.reset
      page.page_tags.reset
      page.tags.reset
    end
    outputs[:exercises].each do |exercise|
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
