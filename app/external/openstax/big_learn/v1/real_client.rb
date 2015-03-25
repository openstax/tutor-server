class OpenStax::BigLearn::V1::RealClient

  include Singleton

  # TODO implement these methods when real API set; use HTTParty, e.g:
  #   response = HTTParty.get(url)
  #   ids = response.parsed_response["questionTopics"].collect{|qt| qt["question"]}

  URL_BASE = "http://api1.biglearn.openstax.org/"
  ADD_EXERCISES_URL = URL_BASE + "facts/questions"
  PROJECTION_EXERCISES_URL = URL_BASE + "projections/questions"

  def add_exercises(exercises)

    payload = { question_tags: [] }

    [exercises].flatten.each do |exercise|
      payload[:question_tags].push({
        question_id: exercise.uid,
        tags: exercise.tags
      })
    end

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
    result["questions"].collect{|q| q["question"]}
  end

  def stringify_tag_search(tag_search)
    case tag_search
    when Hash
      if tag_search.size != 1 then raise IllegalArgument, "too many hash condition" end

      case tag_search.first[0]
      when :_and
        '(' + tag_search.first[1].collect{|ts| stringify_tag_search(ts)}.join(" AND ") + ')'
      when :_or
        '(' + tag_search.first[1].collect{|ts| stringify_tag_search(ts)}.join(" OR ") + ')'
      else raise NotYetImplemented, "Unknown boolean symbol #{condition.first[0]}"
      end

    when String
      '"' + tag_search + '"'
    else raise IllegalArgument
    end
  end

  def handle_result(result)
    raise "BigLearn error #{result.code}; #{result}; #{result.request}" if result.code != 200
  end

end
