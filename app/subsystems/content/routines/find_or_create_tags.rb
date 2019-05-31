class Content::Routines::FindOrCreateTags

  lev_routine express_output: :tags

  protected

  # Input is an array of either:
  #  1) Content::Models::Tags
  #  2) Hashes containing the following fields:
  #       value:       the raw value of the tag
  #       name:        the name of the tag
  #       description: the tag's description
  #       type:        the type of the tag, one of Content::Models::Tag.tag_types
  #       teks:        a raw value of a (possibly non-existent) TEKS tag to link
  #                    to (type must be "lo")
  #
  def exec(ecosystem:, input:)
    tag_objects, hashes = partition_content_tags(input)
    tag_objects.each { |tag| tag.save! unless tag.persisted? }
    outputs[:tags] = tag_objects + find_or_create_ecosystem_tags_from_hash_array(ecosystem, hashes)
  end

  private

  def partition_content_tags(input)
    [input].flatten.partition { |obj| obj.is_a?(Content::Models::Tag) }
  end

  def find_or_create_ecosystem_tags_from_hash_array(ecosystem, hash_array)
    # Collect existing tag values
    hash_values = hash_array.map{ |hash| hash[:value] }
    hash_values = hash_values + hash_array.map{ |hash| hash[:teks] }.compact
    hash_values = hash_values.uniq

    # Find existing tags
    existing_tags = Content::Models::Tag.where(content_ecosystem_id: ecosystem.id,
                                               value: hash_values).to_a
    existing_tag_values = existing_tags.map(&:value)

    # Exclude existing tags
    new_hash_array = hash_array.select { |hash| !existing_tag_values.include?(hash[:value]) }

    # Create new TEKS tags first
    new_hash_teks = new_hash_array.map { |hash| hash[:teks] }.compact.uniq
    existing_teks_tags = existing_tags.select { |tag| new_hash_teks.include?(tag.value) }
    existing_teks_values = existing_teks_tags.map(&:value)

    # Search tag hashes for the TEKS definitions
    new_teks_values = new_hash_teks - existing_teks_values
    new_teks_hashes = new_hash_array.select { |hash| new_teks_values.include?(hash[:value]) }

    # Some TEKS was found that did not previously exist and is not defined in the content
    hashless_teks = new_teks_values - new_teks_hashes.map{ |hash| hash[:value] }
    Rails.logger.warn "TEKS with no definition found: #{hashless_teks.join(', ')}" \
      unless hashless_teks.empty?
    missing_teks_hashes = hashless_teks.map { |teks| { value: teks } }

    # Create new tags for TEKS
    new_teks_tags = (new_teks_hashes + missing_teks_hashes).map do |hash|
      attributes = hash.slice(:value, :name, :description)
                       .merge(content_ecosystem_id: ecosystem.id, tag_type: :teks)
      Content::Models::Tag.create!(attributes)
    end
    teks_tags = existing_teks_tags + new_teks_tags
    teks_map = teks_tags.each_with_object({}) do |tag, hash|
      hash[tag.value] = tag
    end

    # TEKS tags were already created, so exclude them
    new_hash_array = new_hash_array - new_teks_hashes

    # Create non-TEKS tags
    new_non_teks_tags = new_hash_array.map do |hash|
      hash[:tag_type] = hash[:type]
      attributes = hash.slice(:value, :name, :description, :tag_type)
                       .merge(content_ecosystem_id: ecosystem.id)
      new_tag = Content::Models::Tag.create!(attributes)
      teks_value = hash[:teks]

      # If the hash mentions a TEKS tag, link it
      if teks_value
        raise "Can only link TEKS tags to LOs" if !new_tag.lo?

        teks_tag = teks_map[teks_value]
        Content::Models::LoTeksTag.create!(lo: new_tag, teks: teks_tag)
      end

      new_tag
    end

    (existing_tags + existing_teks_tags + new_teks_tags + new_non_teks_tags).uniq
  end

end
