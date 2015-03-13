class Content::ImportExercises

  # This Regex finds the LO's within the exercise tags
  LO_REGEX = /ost-tag-lo-([\w-]+-lo[\d]+)/

  lev_routine

  uses_routine Content::TagResourceWithTopics,
               as: :add_lo,
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

      los = wrapper.tags.collect{|t| LO_REGEX.match(t).try(:[], 1)}.compact.uniq
      run(:add_lo, exercise, wrapper.los)

      outputs[:exercises] << exercise
    end
  end
end
