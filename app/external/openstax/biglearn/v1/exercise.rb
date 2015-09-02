class OpenStax::Biglearn::V1::Exercise

  attr_reader :question_id, :version, :tags

  def initialize(question_id:, version: nil, tags: tags)
    raise IllegalArgument, "`question_id` must be a string" unless question_id.is_a?(String)

    tags = [tags].flatten.compact
    tags = tags.collect{|tag| tag.to_s}

    @question_id = question_id
    @version = version
    @tags = tags
  end

end
