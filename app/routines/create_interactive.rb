class CreateInteractive

  lev_routine

  uses_routine GetOrCreateResource,
               translations: { outputs: {type: :verbatim} }

protected

  def exec(options={}); debugger
    run(GetOrCreateResource, options.slice(:url))
    transfer_errors_from(outputs[:resource], {type: :verbatim}, true)

    outputs[:interactive] = Interactive.create(resource: outputs[:resource])
    transfer_errors_from(outputs[:interactive], {type: :verbatim}, true)

    task = Task.create(details: outputs[:interactive], 
                       title: 'placeholder', 
                       opens_at: options[:opens_at], 
                       due_at: options[:due_at])

    transfer_errors_from(task, {type: :verbatim}, true)
  end

end