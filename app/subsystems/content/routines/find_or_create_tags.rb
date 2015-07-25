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
  def exec(input:)
    tags = input.select{ |ii| ii.is_a?(Content::Models::Tag) }
    hash_array = input.select{ |ii| ii.is_a?(Hash) }
    outputs[:tags] = tags + find_or_create_tags_from_hash_array(hash_array)
  end

  def find_or_create_tags_from_hash_array(hash_array)
    # Find existing tags
    hash_values = hash_array.collect{ |hash| hash[:value] }
    existing_tags = Content::Models::Tag.where(value: hash_values)
    existing_tag_values = existing_tags.collect{ |tag| tag.value }

    # Exclude existing tags
    new_hash_array = hash_array.select{ |hash| !existing_tag_values.include?(hash[:value]) }

    # Create new TEKS tags first
    teks_values = new_hash_array.collect{ |hash| hash[:teks] }.compact.uniq
    existing_teks_tags = Content::Models::Tag.where(value: teks_values)
    existing_teks_values = existing_teks_tags.collect{ |tag| tag.value }

    # Search tag hashes for the TEKS definitions
    new_teks_values = teks_values.select{ |value| !existing_teks_values.include?(value) }
    new_teks_hashes = new_hash_array.select{ |hash| new_teks_values.include?(hash[:value]) }

    # Some TEKS was found that did not previously exist and is not defined in the content
    hashless_teks = new_teks_values - new_teks_hashes.collect{ |hash| hash[:value] }
    Rails.logger.warn "TEKS with no definition found: #{hashless_teks.join(', ')}" \
      unless hashless_teks.empty?
    missing_teks_hashes = hashless_teks.collect{ |teks| {value: teks} }

    # Create new tags for TEKS
    new_teks_tags = (new_teks_hashes + missing_teks_hashes).collect do |hash|
      Content::Models::Tag.create!(hash.slice(:value, :name, :description).merge(tag_type: :teks))
    end
    teks_tags = existing_teks_tags + new_teks_tags
    teks_map = teks_tags.each_with_object({}) do |tag, hash|
      hash[tag.value] = tag
    end

    # TEKS tags were already created, so exclude them
    new_hash_array = new_hash_array - new_teks_hashes

    # Create non-TEKS tags
    new_non_teks_tags = new_hash_array.collect do |hash|
      hash[:tag_type] = hash[:type]
      new_tag = Content::Models::Tag.create!(hash.slice(:value, :name, :description, :tag_type))
      teks_value = hash[:teks]

      # If the hash mentions a TEKS tag, link it
      if teks_value
        raise "Can only link TEKS tags to LOs" if !new_tag.lo?

        teks_tag = teks_map[teks_value]
        Content::Models::LoTeksTag.create!(lo: new_tag, teks: teks_tag)
      end

      new_tag
    end

    existing_tags + new_teks_tags + new_non_teks_tags
  end

end
