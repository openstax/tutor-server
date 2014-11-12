class TagExerciseDefinitionWithTopic

  lev_routine

  uses_routine GetOrCreateTopic

  protected

  def exec(exercise_definition:, topic:)
    run(GetOrCreateTopic, topic: topic, klass: exercise_definition.klass)
    attributes = {topic_id: outputs[:topic].id, exercise_definition_id: exercise_definition.id}
    ExerciseDefinitionTopic.create(attributes) unless ExerciseDefinitionTopic.where(attributes).any?
  end

end