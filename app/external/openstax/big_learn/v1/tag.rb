class OpenStax::BigLearn::V1::Tag

  ###
  ### tag types are on their way out (probably)
  ###

  # TAG_TYPES = %w(topic aggregate filter)

  attr_reader :text #, :types

  def initialize(text) #, *types)
    # if types.empty?
    #   raise IllegalArgument, 'Must specify at least one tag'
    # end

    # types = types.collect{|type| type.to_s}

    # if (types & TAG_TYPES).length != types.length
    #   raise IllegalArgument, 'invalid or duplicate tag type'
    # end

    @text = text
    # @types = types
  end

end