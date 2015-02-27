class Content::ImportExercises

  lev_routine

  uses_routine Content::TagResourceWithTopics,
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
      transfer_errors_from(exercise, {type: :verbatim})

      run(:tag, exercise, wrapper.tags)

      outputs[:exercises] << exercise
    end
  end
end
