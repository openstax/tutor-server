Content::Question = Struct.new(:id, :content_hash, keyword_init: true) do
  def question_hash
    content_hash['questions'].first
  end

  delegate :[], to: :question_hash

  def content
    content_hash.to_json
  end

  def question_content
    question_hash.to_json
  end
end
