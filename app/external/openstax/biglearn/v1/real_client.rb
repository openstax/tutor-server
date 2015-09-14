class OpenStax::Biglearn::V1::RealClient

  # Since we don't know which flavor of SPARFA generated the CLUE,
  # be safe and assume mini SPARFAC, which should expire after 3 minutes (when fast SPARFA runs)
  # All cached CLUEs will expire after the given duration, even if nobody answered any questions
  CLUE_CACHE_DURATION = 3.minutes

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
    learners = get_exchange_read_identifiers_for_roles(roles: roles)
    pool_ids = pools.collect(&:uuid)
    last_answer_times = get_last_answer_times(roles: roles, pools: pools)

    fetch_clues(learners: learners, pool_ids: pool_ids, last_answer_times: last_answer_times)
  end

  private

  # Returns the last answer time for all roles for each pool given
  def get_last_answer_times(roles:, pools:)
    role_ids = roles.collect(&:id)

    pools.collect do |pool|
      # Ignore exercise versions, since Biglearn also ignores them
      exercise_numbers = pool.exercises.collect(&:number)

      last_completed_at = Tasks::Models::TaskedExercise
                            .joins({ task_step: { task: :taskings } }, :exercise)
                            .where(exercise: { number: exercise_numbers },
                                   task_step: { task: { taskings: { entity_role_id: role_ids } } })
                            .maximum(:last_completed_at)
      next if last_completed_at.nil?
      last_completed_at.utc.to_s(:number)
    end
  end

  # Get all the CLUEs from the cache, calling Biglearn only once if needed
  def fetch_clues(learners:, pool_ids:, last_answer_times:)
    # Hash the learners so that the key size remains manageable
    # Sort learners to ensure consistent ordering when digesting
    learner_digest = Digest::SHA256.new
    learners.sort.each do |learner|
      learner_digest << learner.to_s
    end
    learner_digest = learner_digest.to_s

    key_prefix = 'biglearn/clues'

    # The CLUEs returned refer to all given learners at once
    # Each CLUE refers to a single pool, so each pool corresponds to a different cache key
    # The last_answer_times are used for key expiration when someone answers a new question
    cache_keys = pool_ids.each_with_index.collect do |pool_id, index|
      "#{key_prefix}/#{pool_id}/#{learner_digest}-#{last_answer_times[index]}"
    end

    # Read CLUEs for all pools from the cache
    cache_key_clues_map = Rails.cache.read_multi(*cache_keys)

    # Figure out which pools we missed in the cache and create a map
    missed_pool_id_cache_key_map = cache_keys.each_with_index
                                             .each_with_object({}) do |(cache_key, index), hash|
      clue = cache_key_clues_map[cache_key]
      hash[pool_ids[index]] = cache_key if clue.blank?
    end

    if missed_pool_id_cache_key_map.empty?
      # Cache hit for all CLUEs: Don't call Biglearn
      missed_clues = []
    else
      # Call Biglearn (once) to get the missing CLUEs
      query = { learners: learners, pool_ids: missed_pool_id_cache_key_map.keys }
      response = request(:get, clue_uri, params: query)
      result = handle_response(response) || {}
      missed_clues = result['aggregates'] || []

      # Iterate to the CLUEs returned, filling in the cache and the cache_key_clues_map
      missed_clues.each do |clue|
        next if clue.blank?

        pool_id = clue['pool_id']
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
          sample_size_interpretation: interpretation['threshold']
        }

        cache_key = missed_pool_id_cache_key_map[pool_id]

        Rails.cache.write(cache_key, clue_hash, expires_in: CLUE_CACHE_DURATION)

        cache_key_clues_map[cache_key] = clue_hash
      end
    end

    # Return all the CLUEs in the proper order
    cache_keys.each_with_index.each_with_object({}) do |(cache_key, index), hash|
      hash[pool_ids[index]] = cache_key_clues_map[cache_key]
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
