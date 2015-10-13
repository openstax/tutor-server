module Tagger
  # This Regex matches LO's
  LO_REGEX = /[\w-]+-lo[\d-]+/

  # This Regex matches AP LO's
  APLO_REGEX = /[\w-]+-aplo-[\w-]+/

  # This Regex matches Concept Coach section tags
  CC_REGEX = /[\w-]+-ch[\d-]{2}-s[\d-]{2}/

  def self.get_type(tag_string)
    case tag_string
    when LO_REGEX
      :lo
    when APLO_REGEX
      :aplo
    when CC_REGEX
      :cc
    else
      :generic
    end
  end
end
