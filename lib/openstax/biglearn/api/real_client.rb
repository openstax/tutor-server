class OpenStax::Biglearn::Api::RealClient

  # CLUe duration
  # We update CLUes in the background every minute, so we let the cache basically last forever
  CLUE_CACHE_DURATION = 1.year

  # The maximum number of (pools*students) allowed to be sent in each CLUe call to Biglearn
  # At least one pool will always be sent in each request, regardless of this value
  # Setting this value too low will make requests slower.
  # Setting this value too high will cause timeouts.
  # Default is 100 (for example, 50 students and 2 pools on each request)
  CLUE_MAX_POOL_STUDENT_PRODUCT = 100

  # The maximum number of exercises to send to Biglearn on each request
  MAX_EXERCISES_PER_REQUEST = 1500

  # The maximum number of pools to create on Biglearn on each request
  MAX_POOLS_PER_REQUEST = 100

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

  def name
    :real
  end

  def add_exercises(exercises)
    exercises.each_slice(MAX_EXERCISES_PER_REQUEST).map do |exercises|
      options = { body: construct_exercises_payload(exercises).to_json }
      response = request(:post, add_exercises_uri, with_content_type_header(options))
      handle_response(response)
    end
  end

  def add_pools(pools)
    pools.each_slice(MAX_POOLS_PER_REQUEST).flat_map do |pools|
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
  end

  def combine_pools(pool_uuids)
    options = { body: construct_combine_pools_payload(pool_uuids).to_json }
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

  def get_projection_exercises(role:, pool_uuids:, pool_exclusions:,
                               count:, difficulty:, allow_repetitions:)
    # If we have more than one pool uuid, we must first combine them all into a single pool
    pool_uuid = [pool_uuids].flatten.size > 1 ? OpenStax::Biglearn::Api.combine_pools(pool_uuids) : pool_uuids.first

    excluded_pools = pool_exclusions.map do |hash|
      { pool_id: hash[:pool].uuid, ignore_versions: hash[:ignore_versions] }
    end

    payload = {
      learner_id: get_exchange_read_identifiers_for_roles(roles: role).first,
      number_of_questions: count,
      allow_repetition: allow_repetitions ? 'true' : 'false',
      pool_id: pool_uuid,
      excluded_pools: excluded_pools
    }

    options = { body: payload.to_json }
    response = request(:post, projection_exercises_uri, with_content_type_header(options))

    result = handle_response(response)

    # Return the UIDs
    result["questions"].map { |q| q["question"] }
  end

  def get_clues(roles:, pool_uuids:, force_cache_miss: false)
    learners = get_exchange_read_identifiers_for_roles(roles: roles)

    # No learners: map all pools to nil
    return pools.each_with_object({}) { |pool, hash| hash[pool.uuid] = nil } if learners.empty?

    fetch_clues(learners: learners, pool_ids: pool_uuids, force_cache_miss: force_cache_miss)
  end

  private

  def get_exchange_read_identifiers_for_roles(roles:)
    [roles].flatten.compact.map{ |role| role.profile.exchange_read_identifier }
  end

  # Get all the CLUEs from the cache, calling Biglearn only if needed
  def fetch_clues(learners:, pool_ids:, force_cache_miss:)
    key_prefix = 'biglearn/clues'

    # XOR the learner hashes
    learner_cache_key = learners.map{ |learner| Integer(learner, 16) }.reduce(:^).to_s(16)

    # The CLUEs returned refer to all given learners at once
    # Each CLUE refers to a single pool, so each pool corresponds to a different cache key
    cache_key_to_pool_id_map = pool_ids.each_with_object({}) do |pool_id, hash|
      cache_key = "#{key_prefix}/#{learner_cache_key}/#{pool_id}"
      hash[cache_key] = pool_id
    end
    cache_keys = cache_key_to_pool_id_map.keys

    # Read CLUEs for all pools from the cache unless force_cache_miss is true
    cache_key_to_clue_map = force_cache_miss ? {} : Rails.cache.read_multi(*cache_keys)

    # Initialize result set for all cache hits
    pool_id_to_clue_map = cache_key_to_clue_map.each_with_object({}) do |(cache_key, clue), hash|
      pool_id = cache_key_to_pool_id_map[cache_key]
      hash[pool_id] = clue
    end

    # Figure out which cache keys we missed in the cache
    missed_cache_keys = cache_keys - cache_key_to_clue_map.keys

    # Don't call Biglearn if we hit the cache for all the CLUes
    return pool_id_to_clue_map if missed_cache_keys.empty?

    # Figure out which pools we missed in the cache
    missed_pool_id_to_cache_key_map = missed_cache_keys.each_with_object({}) do |cache_key, hash|
      pool_id = cache_key_to_pool_id_map[cache_key]
      hash[pool_id] = cache_key
    end
    missed_pool_ids = missed_pool_id_to_cache_key_map.keys

    # Call Biglearn to get the missing CLUEs
    max_pools_per_request = [CLUE_MAX_POOL_STUDENT_PRODUCT/learners.size, 1].max

    if missed_pool_ids.size > max_pools_per_request
      # Make several requests to Biglearn in parallel
      threads = missed_pool_ids.each_slice(max_pools_per_request).map do |pool_ids|
        Thread.new do
          request_clues(learners: learners, pool_ids: pool_ids,
                        pool_id_to_cache_key_map: missed_pool_id_to_cache_key_map,
                        result_map: pool_id_to_clue_map)
        end
      end

      threads.each(&:join)
    else
      # Just make one inline request
      request_clues(learners: learners, pool_ids: missed_pool_ids,
                    pool_id_to_cache_key_map: missed_pool_id_to_cache_key_map,
                    result_map: pool_id_to_clue_map)
    end

    pool_id_to_clue_map
  end

  def request_clues(learners:, pool_ids:, pool_id_to_cache_key_map:, result_map:)
    query = { learners: learners, pool_ids: pool_ids }
    response = request(:get, clue_uri, params: query)
    result = handle_response(response) || {}
    missed_clues = result['aggregates'] || []

    # Iterate to the CLUes returned, filling in the cache and the result map
    missed_clues.each do |clue|
      next if clue.blank? # Ignore blank CLUes

      pool_id   = clue['pool_id']
      cache_key = pool_id_to_cache_key_map[pool_id]

      next if cache_key.blank? # Ignore unknown pool_ids

      aggregate      = clue['aggregate']
      interpretation = clue['interpretation'] || {}
      confidence     = clue['confidence'] || {}

      clue_hash = {
        value: aggregate,
        value_interpretation: interpretation['level'],
        confidence_interval: [
          confidence['left'],
          confidence['right']
        ],
        confidence_interval_interpretation: interpretation['confidence'],
        sample_size: confidence['sample_size'],
        sample_size_interpretation: interpretation['threshold'],
        unique_learner_count: confidence['unique_learner_count']
      }

      Rails.cache.write(cache_key, clue_hash, expires_in: CLUE_CACHE_DURATION)

      result_map[pool_id] = clue_hash
    end
  end

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
    { question_tags: [exercises].flatten.map do |exercise|
      { question_id: exercise.question_id.to_s,
        version: Integer(exercise.version),
        tags: exercise.tags }
    end }
  end

  def construct_add_pools_payload(pools)
    { sources: pools.map do |pool|
      { questions: pool.exercises.map do |exercise|
        { question_id: exercise.question_id.to_s,
          version:     Integer(exercise.version) }
      end }
    end }
  end

  def construct_combine_pools_payload(pool_uuids)
    { sources: [
      { pools: pool_uuids }
    ] }
  end

  def handle_response(response)
    raise "BiglearnError #{response.status}:\n#{response.body}" if response.status != 200

    JSON.parse(response.body)
  end

end
