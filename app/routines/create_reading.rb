class CreateReading

  lev_routine

  uses_routine GetOrCreateResource,
               translations: { outputs: {type: :verbatim} }

protected

  def exec(options={})
    run(GetOrCreateResource, options.slice(:url, :content))

    outputs[:reading] = Reading.create(resource: outputs[:resource])
    transfer_errors_from(outputs[:reading], {type: :verbatim}, true)

    task = Task.create(details: outputs[:reading], title: 'placeholder', opens_at: options[:opens_at] || Time.now)
    transfer_errors_from(task, {type: :verbatim}, true)
  end

end