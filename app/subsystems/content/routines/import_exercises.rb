class Content::ImportExercises

  lev_routine

  uses_routine Content::TagResource,
               as: :tag,
               translations: { outputs: { type: :verbatim } }

  protected

  # TODO: make this import only exercises from trusted authors
  #       or in some trusted list (for when OS Exercises is public)
  def exec(query_hash)
    outputs[:exercises] = []
    OpenStax::Exercises::V1.exercises(query_hash)['items'].each do |wrapper|
      exercise = Content::Exercise.find_or_initialize_by(url: wrapper.url)
      exercise.title = wrapper.title
      exercise.content = wrapper.content
      exercise.save
      transfer_errors_from(exercise, {type: :verbatim}, true)

      lo_tags = wrapper.los
      non_lo_tags = wrapper.tags - lo_tags
      run(:tag, exercise, lo_tags, tag_type: :lo)
      run(:tag, exercise, non_lo_tags)

      outputs[:exercises] << exercise
    end
  end
end
