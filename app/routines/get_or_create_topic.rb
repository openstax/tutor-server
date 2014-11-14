class GetOrCreateTopic

  lev_routine

  protected

  def exec(topic:, klass:)
    if topic.is_a?(Topic)
      outputs[:topic] = topic
    else
      outputs[:topic] = Topic.where(name: topic.to_s, klass_id: klass.id).first_or_create
      transfer_errors_from(outputs[:topic], {verbatim: true}, true)
    end
  end

end