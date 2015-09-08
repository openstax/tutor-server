class OpenStax::Biglearn::V1::RealClient

  def initialize(biglearn_configuration)
    @server_url   = biglearn_configuration.server_url
    @client_id    = biglearn_configuration.client_id
    @secret       = biglearn_configuration.secret

    # Make Faraday (used by Oauth2) encode arrays without the [], since Biglearn uses CGI
    connection_opts = { request: { params_encoder: Faraday::FlatParamsEncoder } }

    @oauth_client = OAuth2::Client.new(@client_id, @secret, site: @server_url,
                                                            connection_opts: connection_opts)

    @oauth_token  = @oauth_client.client_credentials.get_token unless @client_id.nil?
  end

  def add_exercises(exercises)
    options = { body: construct_exercises_payload(exercises).to_json }
    response = request(:post, add_exercises_uri, with_content_type_header(options))
    handle_response(response)
  end

  def add_pools(pools)
    options = { body: construct_add_pools_payload(pools).to_json }

    response = request(:post, add_pools_uri, with_content_type_header(options))
    body_hash = handle_response(response)

    uuids = body_hash['pool_ids']
    raise "Biglearn returned wrong number of uuids " \
          "(#pools != #uuids) (#{pools.count} != #{uuids.count})" \
      unless uuids.count == pools.count

    nil_uuid_count = uuids.count(&:nil?)
    raise "Biglearn returned #{nil_uuid_count} nil uuids" if nil_uuid_count > 0

    blank_uuid_count = uuids.count(&:blank?)
    raise "Biglearn returned #{blank_uuid_count} blank uuids" if blank_uuid_count > 0

    uuids
  end

  def combine_pools(pools)
    options = { body: construct_combine_pools_payload(pools).to_json }
    response = request(:post, add_pools_uri, with_content_type_header(options))
    body_hash = handle_response(response)

    uuids = body_hash['pool_ids']
    raise "Biglearn returned (#{uuids.count} != 1) uuids " unless uuids.count == 1

    nil_uuid_count = uuids.count(&:nil?)
    raise "Biglearn returned #{nil_uuid_count} nil uuids" if nil_uuid_count > 0

    blank_uuid_count = uuids.count(&:blank?)
    raise "Biglearn returned #{blank_uuid_count} blank uuids" if blank_uuid_count > 0

    uuids.first
  end

  def get_exchange_read_identifiers_for_roles(roles:)
    users = Role::GetUsersForRoles[roles]
    UserProfile::Models::Profile.where(entity_user: users)
                                .collect{ |p| p.exchange_read_identifier }
  end

  def get_projection_exercises(role:, pools:, count:, difficulty:, allow_repetitions:)
    query = {
      learner_id: get_exchange_read_identifiers_for_roles(roles: role).first,
      number_of_questions: count,
      allow_repetition: allow_repetitions ? 'true' : 'false'
    }

    # If we have more than one pool, we must first combine them all into a single pool
    pool = [pools].flatten.size > 1 ? OpenStax::Biglearn::V1.combine_pools(pools) : pools.first

    query = query.merge(pool_id: pool.uuid)

    response = request(:get, projection_exercises_uri, params: query)

    result = handle_response(response)

    # Return the UIDs
    result["questions"].collect { |q| q["question"] }
  end

  def get_clues(roles:, pools:)
    raise "At least one role must be specified when getting a CLUE" if roles.blank?
    raise "At least one pool_id must be specified when getting a CLUE" if pools.blank?

    query = {
      learners: get_exchange_read_identifiers_for_roles(roles: roles),
      pool_ids: pools.collect(&:uuid)
    }

    response = request(:get, clue_uri, params: query)

    result = handle_response(response) || {}

    clues = result['aggregates'] || []

    clues.collect do |clue|
      next if clue.blank?

      aggregate      = clue['aggregate']
      interpretation = clue['interpretation'] || {}
      confidence     = clue['confidence'] || {}

      {
        value: aggregate,
        value_interpretation: interpretation['level'],
        confidence_interval: [
          confidence['left'],
          confidence['right']
        ],
        confidence_interval_interpretation: interpretation['confidence'],
        sample_size: confidence['sample_size'],
        sample_size_interpretation: interpretation['threshold']
      }
    end
  end

  def invalidate_clue_caches(roles:)
    # noop
  end

  private

  def with_content_type_header(options = {})
    options[:headers] ||= {}
    options[:headers].merge!('Content-Type' => 'application/json')
    options
  end

  def request(*args)
    (@oauth_token || @oauth_client).request(*args)
  end

  def add_exercises_uri
    Addressable::URI.join(@server_url, '/facts/questions')
  end

  def add_pools_uri
    Addressable::URI.join(@server_url, '/facts/pools')
  end

  def projection_exercises_uri
    Addressable::URI.join(@server_url, '/projections/questions')
  end

  def clue_uri
    Addressable::URI.join(@server_url, '/knowledge/clue')
  end

  def construct_exercises_payload(exercises)
    { question_tags: [exercises].flatten.collect do |exercise|
      { question_id: exercise.question_id.to_s,
        version: Integer(exercise.version),
        tags: exercise.tags }
    end }
  end

  def construct_add_pools_payload(pools)
    { sources: pools.collect do |pool|
      { questions: pool.exercises.collect do |exercise|
        { question_id: exercise.question_id.to_s,
          version:     Integer(exercise.version) }
      end }
    end }
  end

  def construct_combine_pools_payload(pools)
    { sources: [
      { pools: pools.collect{ |pl| pl.uuid } }
    ] }
  end

  def handle_response(response)
    raise "BiglearnError #{response.status}:\n#{response.body}" if response.status != 200

    JSON.parse(response.body)
  end

end
