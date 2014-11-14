class TagExerciseDefinitionWithTopic

  lev_routine

  uses_routine GetOrCreateTopic,
               translations: { outputs: {type: :verbatim} }

  protected

  def exec(exercise_definition:, topic:)
    run(GetOrCreateTopic, topic: topic, klass: exercise_definition.klass)
    edt = ExerciseDefinitionTopic.where(topic_id: outputs[:topic].id, exercise_definition_id: exercise_definition.id)
                                 .first_or_create
    transfer_errors_from(edt, {verbatim: true}, true)
  end

end