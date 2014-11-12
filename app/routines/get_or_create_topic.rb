class GetOrCreateTopic

  lev_routine

  protected

  def exec(topic:, klass:)
    if topic.is_a?(Topic)
      outputs[:topic] = topic
    else
      attributes = {name: topic.to_s, klass_id: klass.id}
      outputs[:topic] = Topic.where(attributes).first || Topic.create(attributes)
      transfer_errors_from(outputs[:topic], {verbatim: true}, true)
    end
  end

end