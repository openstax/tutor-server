class Content::Routines::TagResource

  lev_routine

  protected

  def exec(resource, tags, options = {})
    resource_class_name = resource.class.name
    tagging_class = options[:tagging_class] || "#{resource_class_name}Tag".constantize
    resource_field = resource_class_name.underscore.split('/').last.to_sym

    outputs[:taggings] = []

    [tags].flatten.compact.each do |tag|
      tagging = tagging_class.find_or_create_by(tag: tag, resource_field => resource)
      outputs[:taggings] << tagging
      transfer_errors_from(tagging, scope: :taggings)
    end
  end

end
