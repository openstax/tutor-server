class Content::Routines::TagResource
  lev_routine

  protected

  def exec(ecosystem:, resource:, tags:, tagging_class: nil, save_tags: true, all_tags: nil)
    all_tags ||= ecosystem.tags.to_a

    # Collect tag attributes and values
    attributes = [tags].flatten.compact.map do |tag|
      case tag
      when Hash
        tag.merge tag_type: tag[:type]
      when Content::Models::Tag
        tag.attributes
      else
        { value: tag }
      end
    end
    attributes_by_value = attributes.index_by { |attr| attr[:value] }
    values = attributes.map { |attr| attr[:value] } + attributes.map { |attr| attr[:teks] }.compact

    # Update and collect existing tags
    existing_tags = all_tags.filter { |tag| values.include? tag.value }
    updated_tags = existing_tags.map do |tag|
      attrs = attributes_by_value[tag.value]
      next if attrs.nil?

      tag.attributes = attrs.slice(:name, :description, :tag_type)
      tag.update_tag_type
      tag
    end.compact

    # Filter new tags
    existing_tag_values = existing_tags.map(&:value)
    new_attributes = attributes.select { |attr| !existing_tag_values.include?(attr[:value]) }

    # Create new tags
    new_tags = new_attributes.map do |hash|
      Content::Models::Tag.new(
        hash.slice(:value, :name, :description, :tag_type).merge(ecosystem: ecosystem)
      ).tap do |tag|
        tag.update_tag_type
        tag.update_data_and_visible
      end
    end

    outputs.tags = existing_tags + new_tags
    outputs.all_tags = all_tags + new_tags

    resource_class_name = resource.class.name
    tagging_class ||= "#{resource_class_name}Tag".constantize
    resource_field = resource_class_name.underscore.split('/').last.to_sym
    tagging_field = tagging_class.name.tableize.split('/').last.to_sym

    # Avoid duplicate tags
    existing_taggings = resource.send(tagging_field)
    existing_tag_ids = existing_taggings.map(&:content_tag_id)
    existing_tags = existing_tags.reject { |tag| existing_tag_ids.include?(tag.id) }

    # Tag the resource
    outputs.taggings = (existing_tags + new_tags).map do |tag|
      tagging_class.new(tag: tag, resource_field => resource).tap do |tagging|
        existing_taggings << tagging
      end
    end

    resource.tags.reset

    return unless save_tags

    Content::Models::Tag.import updated_tags + new_tags, validate: false, on_duplicate_key_update: {
      conflict_target: [ :value, :content_ecosystem_id ],
      columns: [ :name, :description, :tag_type ]
    }

    ecosystem.tags.reset
  end
end
