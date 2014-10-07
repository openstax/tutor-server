class GetOrCreateResource

  lev_routine

protected

  def exec(options={})
    url = options[:url]
    content = options[:content]
    immutable = options[:immutable] || false

    # TODO based on the URL, retrieve the appropriate content and mark the immutable field
    # correctly; also make sure the resource doesn't already exist (if it does, return the
    # existing)

    outputs[:resource] = Resource.create(url: url, content: content)
  end

end