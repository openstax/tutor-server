class OpenStax::Biglearn::V1::Exercise

  attr_reader :question_id, :version, :tags

  def initialize(question_id:, version: nil, tags: tags)
    tags = [tags].flatten.compact
    tags = tags.collect{|tag| tag.to_s}

    @question_id = question_id
    @version = version
    @tags = tags
  end


end
