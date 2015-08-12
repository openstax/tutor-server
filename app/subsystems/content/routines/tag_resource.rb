class Content::Routines::TagResource

  lev_routine

  protected

  def exec(resource, tags, options = {})
    save = options[:save].nil? ? true : options[:save]
    resource_class_name = resource.class.name
    tagging_class = options[:tagging_class] || "#{resource_class_name}Tag".constantize
    resource_field = resource_class_name.underscore.split('/').last.to_sym

    tags = [tags].flatten.compact

    if resource.persisted?
      existing_tag_ids = tagging_class.where(tag: tags, resource_field => resource)
                                      .pluck(:content_tag_id)
      tags = tags.select{ |tag| !existing_tag_ids.include?(tag.id) }
    end

    outputs[:taggings] = tags.collect do |tag|
      tagging_class.new(tag: tag, resource_field => resource)
    end

    tagging_class.import outputs[:taggings] if save
  end

end
