class CreateExercise

  lev_routine

  uses_routine GetOrCreateResource,
               translations: { outputs: {type: :verbatim} }

protected

  def exec(task, title, options={})

    # TODO ExerciseDefinition should contain a Resource

    run(GetOrCreateResource, options.slice(:url, :content))
    transfer_errors_from(outputs[:resource], {type: :verbatim}, true)

    outputs[:exercise] = Exercise.create(resource: outputs[:resource])
    transfer_errors_from(outputs[:exercise], {type: :verbatim}, true)

    outputs[:task_step] = TaskStep.create(details: outputs[:exercise], title: title, task: task)
    transfer_errors_from(outputs[:task_step], {type: :verbatim}, true)
  end

end