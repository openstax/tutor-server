class GetOrCreateTopic

  lev_routine

  protected

  def exec(topic:, klass:)
    if topic.is_a?(Topic)
      outputs[:topic] = topic
    else
      topic_name = topic.to_s
      outputs[:topic] = Topic.where(name: topic_name).first || Topic.create(name: topic_name, klass: klass)
      transfer_errors_from(outputs[:topic], {verbatim: true}, true)
    end
  end

end