class Content::Routines::ImportExercises

  lev_routine

  uses_routine Content::Routines::FindOrCreateTags, as: :find_or_create_tags
  uses_routine Content::Routines::TagResource, as: :tag

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

      tags = run(:find_or_create_tags, input: wrapper.tag_hashes).outputs.tags

      run(:tag, exercise, tags, tagging_class: Content::Models::ExerciseTag)

      outputs[:exercises] << exercise
    end
  end
end
