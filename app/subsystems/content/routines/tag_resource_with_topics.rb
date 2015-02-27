class Content::TagResourceWithTopics

  lev_routine

  protected

  def exec(resource, topics, options = {})
    resource_class_name = resource.class.name
    tag_class = options[:tag_class] || \
                "#{resource_class_name}Topic".constantize
    resource_field = resource_class_name.underscore.gsub('/','_').to_sym

    outputs[:topics] = []
    outputs[:tags] = []
    topics.each do |t|
      topic = t.is_a?(Content::Topic) ? t : Content::Topic.find_or_create_by(name: t.to_s)
      outputs[:topics] << topic
      transfer_errors_from(topic, scope: :topics)

      tag = tag_class.find_or_create_by(content_topic: topic,
                                        resource_field => resource)
      outputs[:tags] << tag
      transfer_errors_from(tag, scope: :tags)
    end
  end

end
