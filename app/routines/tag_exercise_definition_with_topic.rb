class TagExerciseDefinitionWithTopic

  lev_routine

  uses_routine GetOrCreateTopic

  protected

  def exec(exercise_definition:, topic:)
    topic = run(GetOrCreateTopic, topic: topic, klass: exercise_definition.klass).outputs.topic

    edt_attributes = {topic_id: topic.id, exercise_definition_id: exercise_definition.id}
    return if ExerciseDefinitionTopic.where(edt_attributes).any?
    ExerciseDefinitionTopic.create(edt_attributes)
  end

end