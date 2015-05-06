class Content::Routines::ImportExercises

  lev_routine

  uses_routine Content::Routines::TagResource,
               as: :tag,
               translations: { outputs: { type: :verbatim } }

  protected

  # TODO: make this import only exercises from trusted authors
  #       or in some trusted list (for when OS Exercises is public)
  def exec(query_hash)
    outputs[:exercises] = []
    OpenStax::Exercises::V1.exercises(query_hash)['items'].each do |wrapper|
      exercise = Content::Models::Exercise.find_or_initialize_by(url: wrapper.url)
      uid = wrapper.uid
      number_version = uid.split('@')
      exercise.number = number_version.first
      exercise.version = number_version.last
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
