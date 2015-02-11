class TagObjectWithTopics

  TAG_CLASSES = {
    'page' => PageTopic,
    'exercise' => ExerciseTopic
  }

  lev_routine

  protected

  def exec(object, topics)
    class_name = object.class.name.downcase
    outputs[:tag_class] = TAG_CLASSES[class_name]

    fatal_error(code: :tag_class_not_found,
                message: "No Topic tag class found for #{object.class.name}") \
      if outputs[:tag_class].nil?

    outputs[:topics] = []
    outputs[:tags] = []

    topics.each do |t|
      topic = t.is_a?(Topic) ? t : Topic.find_or_create_by(name: t.to_s)
      outputs[:topics] << topic
      transfer_errors_from(topic, scope: :topics)

      tag = outputs[:tag_class].find_or_create_by(topic: topic,
                                                  class_name => object)
      outputs[:tags] << tag
      transfer_errors_from(tag, scope: :tags)
    end
  end

end
