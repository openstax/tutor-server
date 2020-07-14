module Tagger
  # Since we no longer have the explicit "ch" and "s", better be safe and require lo or aplo
  BOOK_LOCATION_REGEX = /\A(?:ap)?lo:[\w-]+:(\d+)-(\d+)-[\w-]+\z/
  OLD_BOOK_LOCATION_REGEX = /ch(\d+)-s(\d+)/

  # If the tag string matches, it is considered to be of that type
  # This map is used to determine tag types for Exercises
  # Non-CC Pages do not use this map
  # (instead, they infer the tag type from where it appears in the page)
  TAG_TYPE_REGEXES = HashWithIndifferentAccess.new({
    # http://stackoverflow.com/a/12843265
    id: /\Aid:[\w-]+:(\d+)\z/,
    cnxmod: /\A(?:context-)?cnxmod:([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})\z/,
    lo: /\A(?:lo:[\w-]+:\d+-\d+-\d+|[\w-]+-lo\d+)\z/,
    aplo: /\A(?:aplo:[\w-]+:[\w.-]+|[\w-]+-aplo-[\w-]+)\z/,
    dok: /\Adok:?(\d+)\z/,
    blooms: /\Ablooms[:-](\d+)\z/,
    time: /\Atime[:-](\w+)\z/,
    teks: /\A(?:teks:|ost-tag-teks-)[\w-]+-(\w+)\z/,
    requires_context: /\Arequires-context:(?:y(?:es)?|t(?:rue)?)\z/,
    cnxfeature: /\A(?:context-)?cnxfeature:([\w-]+)\z/
  })

  # The capture from the regex above is substituted into the template to form the tag name
  TAG_NAME_TEMPLATES = HashWithIndifferentAccess.new({
    dok: "DOK: %d",
    blooms: "Blooms: %d",
    time: "Length: %.1s"
  })

  def self.get_type(tag_string)
    TAG_TYPE_REGEXES.each { |type, regex| return type.to_sym if regex.match(tag_string) }
    :generic
  end

  def self.get_data(type, tag_string)
    regex = TAG_TYPE_REGEXES[type]
    return if regex.nil?

    regex.match(tag_string).try(:[], 1)
  end

  def self.get_name(type, data)
    template = TAG_NAME_TEMPLATES[type]
    return if template.nil?

    template % data.capitalize
  end

  def self.get_hash(tag_string)
    type = get_type(tag_string)
    data = get_data(type, tag_string)
    name = get_name(type, data)
    {
      value: tag_string,
      name: name,
      type: type
    }
  end

  def self.get_book_location(value)
    matches = BOOK_LOCATION_REGEX.match(value)
    matches ||= OLD_BOOK_LOCATION_REGEX.match(value)
    matches.nil? ? [] : [matches[1].to_i, matches[2].to_i]
  end
end
