require_relative './v1/configuration'
require_relative './v1/pool'
require_relative './v1/exercise'
require_relative './v1/fake_client'
require_relative './v1/real_client'

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
  def self.get_clues(roles:, pools:, cache_for: nil, force_cache_miss: false)
    roles = [roles].flatten.compact
    pools = [pools].flatten.compact

    # No pools given: empty map
    return {} if pools.empty?

    # No roles given: map all pools to nil
    return pools.each_with_object({}) { |pool, hash| hash[pool.uuid] = nil } if roles.empty?

    clue = client.get_clues(roles: roles, pools: pools,
                            cache_for: cache_for, force_cache_miss: force_cache_miss)
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
  def self.fake_client
    FakeClient.new(configuration)
  end

  def self.real_client
    RealClient.new(configuration)
  end

  def self.use_real_client
    @client = real_client
  end

  def self.use_fake_client
    @client = fake_client
  end

  private

  def self.client
    begin
      @client ||= real_client
    rescue StandardError => error
      raise ClientError.new("initialization failure", error)
    end
  end

end
