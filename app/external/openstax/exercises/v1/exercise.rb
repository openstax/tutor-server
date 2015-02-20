class OpenStax::Exercises::V1::Exercise

  attr_reader :url, :content

  def initialize(url, content)
    @url = url
    @content = content || '{}'
  end

  def content_hash
    @content_hash ||= JSON.parse(content)
  end

  def title
    @title ||= content_hash['title']
  end

  def answers
    @answers ||= content_hash['questions'].first['answers']
  end

  def correct_answer_id
    @correct_answer_id ||= answers.select{|a| a['correctness'] >= 1}
                                  .first['id']
  end

  def feedback_map
    @feedback_map ||= Hash[*answers.collect{|a| [a['id'], a['feedback_html']]}
                                   .flatten]
  end

  def feedback_html(answer_id)
    feedback_map[answer_id] || ''
  end

end
