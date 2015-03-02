class OpenStax::Exercises::V1::Exercise

  BASE_URL = 'http://exercises.openstax.org/exercises'

  attr_reader :content

  def initialize(content)
    @content = content || '{}'
  end

  def content_hash
    @content_hash ||= JSON.parse(content)
  end

  def uid
    @uid ||= content_hash['uid']
  end
  alias_method :id, :uid

  def url
    @url ||= "#{BASE_URL}/#{uid}"
  end

  def title
    @title ||= content_hash['title']
  end

  def tags
    @tags ||= content_hash['tags']
  end

  def questions
    @questions ||= content_hash['questions']
  end

  def answers
    #TODO: handle multiple questions in 1 Exercise
    @answers ||= questions.first['answers']
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
