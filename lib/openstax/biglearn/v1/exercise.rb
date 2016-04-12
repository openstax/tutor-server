class OpenStax::Biglearn::V1::Exercise

  attr_reader :question_id, :version, :tags

  def initialize(question_id:, version: nil, tags:)
    raise IllegalArgument, "`question_id` must be a string" unless question_id.is_a?(String)

    tags = [tags].flatten.compact
    tags = tags.map{|tag| tag.to_s}

    @question_id = question_id
    @version = version
    @tags = tags
  end

  def number
    question_id.chomp('/').split('/').last
  end

end
