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

    wrappers = OpenStax::Exercises::V1.exercises(query_hash)['items']
    wrapper_urls = wrappers.uniq{ |wrapper| wrapper.url }

    wrapper_tag_hashes = wrappers.collect{ |wrapper| wrapper.tag_hashes }.flatten
                                 .uniq{ |hash| hash[:value] }
    tags = run(:find_or_create_tags, ecosystem: ecosystem, input: wrapper_tag_hashes).outputs.tags

    wrappers.each do |wrapper|
      exercise_page = page.respond_to?(:call) ? page.call(wrapper) : page
      exercise = Content::Models::Exercise.new(url: wrapper.url,
                                               number: wrapper.number,
                                               version: wrapper.version,
                                               title: wrapper.title,
                                               content: wrapper.content,
                                               page: exercise_page)
      transfer_errors_from(exercise, {type: :verbatim}, true)

      relevant_tags = tags.select{ |tag| wrapper.tags.include?(tag.value) }
      outputs[:taggings] = run(:tag, exercise, relevant_tags,
                               tagging_class: Content::Models::ExerciseTag,
                               save: false).outputs.taggings

      exercise.exercise_tags = outputs[:taggings]
      outputs[:exercises] << exercise
    end

    Content::Models::Exercise.import! outputs[:exercises], recursive: true

    outputs[:exercises].each{ |exercise| exercise.tags.reset }
  end
end
