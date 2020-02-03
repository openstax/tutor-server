class Content::Routines::TagResource
  lev_routine

  protected

  def exec(resource, tags, options = {})
    save = options[:save].nil? ? true : options[:save]
    resource_class_name = resource.class.name
    tagging_class = options[:tagging_class] || "#{resource_class_name}Tag".constantize
    resource_field = resource_class_name.underscore.split('/').last.to_sym
    tagging_field = tagging_class.name.tableize.split('/').last.to_sym

    tags = [tags].flatten.compact

    # Avoid duplicate tags
    existing_taggings = resource.send(tagging_field)
    existing_tag_ids = existing_taggings.map(&:content_tag_id)
    new_tags = tags.reject{ |tag| existing_tag_ids.include?(tag.id) }

    outputs.taggings = new_tags.map do |tag|
      tagging_class.new(tag: tag, resource_field => resource).tap do |tagging|
        existing_taggings << tagging unless save
      end
    end

    return unless save

    tagging_class.import outputs.taggings, validate: false

    # Reset associations so they get reloaded the next time they are used
    existing_taggings.reset
    resource.tags.reset
  end
end
