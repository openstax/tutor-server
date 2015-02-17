class TagResourceWithTopics

  lev_routine

  protected

  def exec(resource, topics)
    outputs[:topics] = []
    outputs[:tags] = []

    topics.each do |t|
      topic = t.is_a?(Topic) ? t : Topic.find_or_create_by(name: t.to_s)
      outputs[:topics] << topic
      transfer_errors_from(topic, scope: :topics)

      tag = ResourceTopic.find_or_create_by(topic: topic,
                                            resource: resource)
      outputs[:tags] << tag
      transfer_errors_from(tag, scope: :tags)
    end
  end

end
