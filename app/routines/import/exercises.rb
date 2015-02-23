class Import::Exercises

  lev_routine

  uses_routine TagResourceWithTopics,
               as: :tag,
               translations: { outputs: { type: :verbatim } }

  protected

  def exec(query_hash)
    outputs[:exercises] = []
    wrappers = OpenStax::Exercises::V1.exercises(query_hash)['items']
    wrappers.each do |wrapper|
      exercise = Exercise.find_or_initialize_by(url: wrapper.url)
      exercise.title = wrapper.title
      exercise.content = wrapper.content
      exercise.save
      transfer_errors_from(outputs[:exercise], {type: :verbatim})

      run(:tag, exercise, wrapper.tags)

      outputs[:exercises] << exercise
    end
  end
end
