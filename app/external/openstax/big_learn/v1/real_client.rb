class OpenStax::BigLearn::V1::RealClient
  include Singleton

  # TODO implement these methods when real API set; use HTTParty, e.g:
  #   response = HTTParty.get(url)
  #   ids = response.parsed_response["questionTopics"].collect{|qt| qt["question"]}

  URL_BASE = "http://api1.biglearn.openstax.org/"
  ADD_EXERCISES_URL = URL_BASE + "facts/questions"
  PROJECTION_EXERCISES_URL = URL_BASE + "projections/questions"

  def add_exercises(exercises)
    payload = construct_exercises_payload(exercises)
    result = HTTParty.post(ADD_EXERCISES_URL,
                           body: payload.to_json,
                           headers: { 'Content-Type' => 'application/json' })
    handle_result(result)
  end

  def get_projection_exercises(user:, tag_search:, count:,
                               difficulty:, allow_repetitions:)
    query = {
      learner_id: 123,
      number_of_questions: count,
      tag_query: stringify_tag_search(tag_search),
      allow_repetition: allow_repetitions ? 'true' : 'false'
    }

    result = HTTParty.get(PROJECTION_EXERCISES_URL, query: query)

    handle_result(result)

    # Return the UIDs
    result["questions"].collect { |q| q["question"] }
  end

  def stringify_tag_search(tag_search)
    case tag_search
    when Hash
      raise IllegalArgument, "too many hash conditions" if tag_search.size != 1
      stringify_tag_search_hash(tag_search.first)
    when String
      '"' + tag_search + '"'
    else
      raise IllegalArgument
    end
  end

  private
  def construct_exercises_payload(exercises)
    payload = { question_tags: [] }
    [exercises].flatten.each do |exercise|
      payload[:question_tags].push({
        question_id: exercise.uid,
        tags: exercise.tags
      })
    end
    payload
  end

  def handle_result(result)
    if result.code != 200
      raise "BigLearn error #{result.code}; #{result}; #{result.request}"
    end
  end

  def stringify_tag_search_hash(conditions)
    case conditions[0]
    when :_and
      str = '('
      str += join_tag_searches(conditions[1], 'AND')
      str += ')'
    when :_or
      str = '('
      str += join_tag_searches(conditions[1], 'OR')
      str += ')'
    else
      raise NotYetImplemented, "Unknown boolean symbol #{conditions[0]}"
    end
  end

  def join_tag_searches(tag_searches, op)
    tag_searches.collect { |ts| stringify_tag_search(ts) }.join(" #{op} ")
  end
end
