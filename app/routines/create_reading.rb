class CreateReading

  lev_routine

  uses_routine GetOrCreateResource,
               translations: { outputs: {type: :verbatim} }

protected

  def exec(options={})
    run(GetOrCreateResource, options.slice(:url, :content))
    outputs[:reading] = Reading.create(resource: outputs[:resource])
    Task.create(details: outputs[:reading], title: 'placeholder')
  end

end