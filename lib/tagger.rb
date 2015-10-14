module Tagger
  # If the tag string matches, it is considered to be of that type
  TAG_TYPE_REGEXES = {
    lo: /[\w-]+-lo[\d-]+/,
    aplo: /[\w-]+-aplo-[\w-]+/,
    cc: /[\w-]+-ch[\d-]{2}-s[\d-]{2}/,
    dok: /^dok(\d+)$/,
    blooms: /^blooms-(\d+)$/,
    length: /^time-(\w+)$/,
    teks: /^ost-tag-teks-.*-(.+)$/
  }

  # The capture from the regex above is substituted into the template to form the tag name
  TAG_NAME_TEMPLATES = {
    dok: "DOK: %d",
    blooms: "Blooms: %d",
    length: "Length: %.1s"
  }

  def self.get_type(tag_string)
    TAG_TYPE_REGEXES.each{ |type, regex| return type if regex.match?(tag_string) }
    :generic
  end

  def self.get_name(tag_string, type)
    template = TAG_NAME_TEMPLATES[type]
    return tag_string if template.nil?

    capture = TAG_TYPE_REGEXES[type].match(tag_string)[1]
    template % capture.capitalize
  end

  def self.get_hash(tag_string)
    type = get_type(tag_string)
    name = get_name(tag_string, type)
    {
      value: tag_string,
      name: name,
      type: type
    }
  end
end
