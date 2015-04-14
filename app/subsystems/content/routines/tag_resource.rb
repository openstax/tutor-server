class Content::Routines::TagResource

  lev_routine

  protected

  def exec(resource, tags, options = {})
    resource_class_name = resource.class.name
    tagging_class = options[:tagging_class] || \
                      "#{resource_class_name}Tag".constantize
    resource_field = resource_class_name.underscore.split('/').last.to_sym
    tag_type = options[:tag_type] || 0
    outputs[:tag_type] = tag_type

    outputs[:tags] = []
    outputs[:taggings] = []
    [tags].flatten.compact.each do |t|
      tag = t.is_a?(Content::Models::Tag) ? \
            t : Content::Models::Tag.find_or_initialize_by(value: t.to_s)
      unless tag.persisted?
        tag.tag_type = tag_type
        tag.save!
      end

      outputs[:tags] << tag
      transfer_errors_from(tag, scope: :tags)

      tagging = tagging_class.find_or_create_by(tag: tag,
                                                resource_field => resource)
      outputs[:taggings] << tagging
      transfer_errors_from(tagging, scope: :taggings)
    end
  end

end
