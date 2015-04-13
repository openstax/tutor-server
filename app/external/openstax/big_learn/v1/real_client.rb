class OpenStax::BigLearn::V1::RealClient
  def initialize(configuration)
    @client_id = configuration.client_id
    @secret = configuration.secret
    @server_url = configuration.server_url
    @oauth_client = OAuth2::Client.new(@client_id, @secret, site: @server_url)
    @oauth_token = @oauth_client.client_credentials.get_token if @client_id
  end

  # TODO implement these methods when real API set; use HTTParty, e.g:
  #   response = HTTParty.get(url)
  #   ids = response.parsed_response["questionTopics"].collect{|qt| qt["question"]}
  def add_exercises(exercises)
    payload = construct_exercises_payload(exercises)
    result = post(add_exercises_url, payload)
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

    result = get(projection_exercises_url, query: query)

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
  def post(url, body)
    HTTParty.post(url,
                  body: body.to_json,
                  headers: { 'Content-Type' => 'application/json' })
  end

  def get(url, params = {})
    HTTParty.get(url, params)
  end

  def add_exercises_url
    @server_url + 'facts/questions'
  end

  def projection_exercises_url
    @server_url + 'projections/questions'
  end

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
