class Content::Routines::FindOrCreateTag
  lev_routine

  protected

  # Input can be one of three things:
  #  1) a Content::Models::Tag
  #  2) a String containing the value of the tag
  #  3) a Hash containing the following fields:
  #       value:       the raw value of the tag
  #       name:        the name of the tag
  #       description: the tag's description
  #       type:        the type of the tag, one of Content::Models::Tag.tag_types
  #       teks:        a raw value of a (possibly non-existent) TEKS tag to link
  #                    to (type must be "lo")
  # Type can be set optionally for inputs of type String, must be one of
  #   Content::Models::Tag.tag_types
  #
  def exec(input:, type: nil)

    outputs[:tag] =
      case input
      when Content::Models::Tag
        input
      when Hash
        find_or_create_tag_from_hash(input)
      when String
        find_or_create_tag_from_string(input, type)
      end

    outputs[:tag].save! unless outputs[:tag].persisted?
  end

  def find_or_create_tag_from_string(string, type)
    Content::Models::Tag.find_or_create_by(value: string, tag_type: type)
  end

  def find_or_create_tag_from_hash(hash)
    tag = Content::Models::Tag.find_or_initialize_by(value: hash[:value])

    tag.update_attributes(
      name: hash[:name],
      description: hash[:description],
      tag_type: hash[:tag_type]
    )

    # If the hash mentions a TEKS tag, link it

    teks_value = hash[:teks]

    if teks_value
      raise "Can only link TEKS tags to LOs" if tag.tag_type != "lo"

      teks_tag = Content::Models::Tag.find_or_initialize_by(value: teks_value.to_s)
      Content::Models::LoTeksTag.create(lo: tag, teks: teks_tag)
    end

    tag
  end
end
