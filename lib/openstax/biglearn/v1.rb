require_relative './v1/configuration'
require_relative './v1/pool'
require_relative './v1/exercise'
require_relative './v1/fake_client'
require_relative './v1/real_client'
require_relative './v1/local_clue'
require_relative './v1/local_query_client'

module OpenStax::Biglearn::V1

  #
  # API Wrappers
  #

  # Adds the given array of OpenStax::Biglearn::V1::Exercise to Biglearn
  def self.add_exercises(exercises)
    client.add_exercises(exercises)
  end

  # Adds the given array of OpenStax::Biglearn::V1::Pool to Biglearn
  def self.add_pools(pools)
    uuids = client.add_pools(pools)
    pools.each_with_index{ |pool, ii| pool.uuid = uuids[ii] }
    pools
  end

  # Creates a new OpenStax::Biglearn::V1::Pool in Biglearn
  # by combining the exercises in all of the given pools
  def self.combine_pools(pools)
    OpenStax::Biglearn::V1::Pool.new(uuid: client.combine_pools(pools))
  end

  # Returns a number of recommended exercises for the given role and pools.
  # Pools are combined into a single pool before the call to Biglearn.
  # May return less than the desired number if allow_repetitions is false.
  def self.get_projection_exercises(role:,
                                    pools:, pool_exclusions: [],
                                    count: 1, difficulty: 0.5, allow_repetitions: true)
    exercises = client.get_projection_exercises(role: role,
                                                pools: pools, pool_exclusions: pool_exclusions,
                                                count: count, difficulty: difficulty,
                                                allow_repetitions: allow_repetitions)

    num_exercises = (exercises || []).size

    if num_exercises != count
      Rails.logger.warn {
        "Biglearn.get_projection_exercises only returned #{num_exercises} of #{count} " +
        "requested exercises [role: #{role}, pools: #{(pools || []).map{ |pl| pl.uuid }}, " +
        "difficulty: #{difficulty}, " +
        "allow_repetitions: #{allow_repetitions}] exercises = #{exercises}"
      }
    end

    exercises
  end

  # Return a CLUe value for the specified set of roles and pools.
  # A map of pool uuids to CLUe values is returned. Each pool is associated with one CLUe.
  # Each CLUe refers to one specific pool, but uses all roles given.
  # May return nil if no CLUe is available
  # (e.g. no exercises in the pools or confidence too low).
  def self.get_clues(roles:, pools:, force_cache_miss: false)
    roles = [roles].flatten.compact
    pools = [pools].flatten.compact

    # No pools given: empty map
    return {} if pools.empty?

    # No roles given: map all pools to nil
    return pools.each_with_object({}) { |pool, hash| hash[pool.uuid] = nil } if roles.empty?

    clue = client.get_clues(roles: roles, pools: pools, force_cache_miss: force_cache_miss)
  end

  #
  # Configuration
  #

  def self.configure
    yield configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  # Accessor for the fake client, which has some extra fake methods on it
  def self.new_fake_client
    new_client_call { FakeClient.new(configuration) }
  end

  def self.new_real_client
    new_client_call { RealClient.new(configuration) }
  end

  def self.new_local_query_client
    new_client_call { LocalQueryClient.new(new_real_client) }
  end

  def self.use_real_client
    use_client_named(:real)
  end

  def self.use_fake_client
    use_client_named(:fake)
  end

  def self.use_client_named(client_name)
    @forced_client_in_use = true
    @client = new_client(client_name)
  end

  def self.default_client_name
    # The default Biglearn client is set via an admin console setting of the
    # client's name (real, fake, or local_query).  The code below will override
    # this default name to 'fake' if (a) the stub configuration flag is set or
    # (b) if stub flag isn't set at all and we are not in production.
    #
    # So for developers who don't set the flag, they'll get the fake client. If
    # developers want to use other than the fake client, they'll need to explicitly
    # set the flag to false.

    secrets = Rails.application.secrets.openstax['biglearn']
    stub = secrets['stub'].nil? ? !Rails.env.production? : secrets['stub']
    stub ? :fake : Settings::Db.store.biglearn_client
  end

  def self.client
    # We normally keep a cached version of the client in use.  If a caller
    # (normally a spec) has said to use a specific client, we don't want to
    # change the client.  Howver if this is not the case and the client's
    # name no longer matches the admin DB setting, change it out.

    if @client.nil? || (!@forced_client_in_use && @client.name != default_client_name)
      @client = new_client(default_client_name)
    end
    @client
  end

  private

  def self.new_client(name)
    case name
    when :local_query
      new_local_query_client
    when :real
      new_real_client
    when :fake
      new_fake_client
    else
      raise "Invalid client name (#{name}); don't know which Biglearn client to make"
    end
  end

  def self.new_client_call
    begin
      yield
    rescue StandardError => e
      raise "Biglearn client initialization error: #{e.message}"
    end
  end

end
