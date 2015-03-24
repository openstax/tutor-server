class OpenStax::BigLearn::V1::RealClient

  include Singleton

  # TODO implement these methods when real API set; use HTTParty, e.g:
  #   response = HTTParty.get(url)
  #   ids = response.parsed_response["questionTopics"].collect{|qt| qt["question"]}

  def add_tags(tags)
    raise NotYetImplemented
  end

  def add_exercises(exercises)
    raise NotYetImplemented
  end

  def get_projection_exercises(user:, topic_tags:, filter_tags:, 
                               count:, difficulty:, allow_repetitions:)
    raise NotYetImplemented
  end

end
