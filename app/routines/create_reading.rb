class CreateReading

  lev_routine

  uses_routine GetOrCreateResource,
               translations: { outputs: {type: :verbatim} }

protected

  def exec(task, options={})
    run(GetOrCreateResource, options.slice(:url, :content))
    transfer_errors_from(outputs[:resource], {type: :verbatim}, true)

    outputs[:reading] = Reading.create(resource: outputs[:resource])
    transfer_errors_from(outputs[:reading], {type: :verbatim}, true)

    outputs[:task_step] = TaskStep.create(details: outputs[:reading], title: 'TODO get this from module', task: task)
    transfer_errors_from(outputs[:task_step], {type: :verbatim}, true)
  end

end