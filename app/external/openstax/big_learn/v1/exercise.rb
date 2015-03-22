class OpenStax::BigLearn::V1::Exercise

  TAG_TYPES = %w(topic aggregate filter)

  attr_reader :text, :type

  def initialize(uid, *tags)
    if tags.empty?
      raise IllegalArgument, 'Must specify at least one tag'
    end

    tags = tags.collect{|tag| tag.to_s}

    @text = text
    @tags = tags
  end


end