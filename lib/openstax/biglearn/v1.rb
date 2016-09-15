require_relative './v1/configuration'
require_relative './v1/pool'
require_relative './v1/exercise'
require_relative './v1/fake_client'
require_relative './v1/real_client'
require_relative './v1/local_clue'
require_relative './v1/local_query_client'

module OpenStax::Biglearn::V1

  extend Configurable
  extend Configurable::ClientMethods
  extend MonitorMixin

  class << self

    #
    # API Wrappers
    #

    # Adds the given array of OpenStax::Biglearn::V1::Exercise to Biglearn
    def add_exercises(exercises)
      client.add_exercises(exercises)
    end

    # Adds the given array of OpenStax::Biglearn::V1::Pool to Biglearn
    def add_pools(pools)
      uuids = client.add_pools(pools)
      pools.each_with_index{ |pool, ii| pool.uuid = uuids[ii] }
      pools
    end

    # Creates a new OpenStax::Biglearn::V1::Pool in Biglearn
    # by combining the exercises in all of the given pool uuids
    def combine_pools(pool_uuids)
      OpenStax::Biglearn::V1::Pool.new(uuid: client.combine_pools(pool_uuids))
    end

    # Returns a number of recommended exercises for the given role and pools.
    # Pools are combined into a single pool before the call to Biglearn.
    # May return less than the desired number if allow_repetitions is false.
    def get_projection_exercises(role:, pools:, pool_exclusions: [],
                                 count: 1, difficulty: 0.5, allow_repetitions: true)
      pool_uuids = pools.map(&:uuid)
      exercises = client.get_projection_exercises(role: role,
                                                  pool_uuids: pool_uuids,
                                                  pool_exclusions: pool_exclusions,
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
    def get_clues(roles:, pools:, force_cache_miss: false)
      roles = [roles].flatten.compact
      pool_uuids = [pools].flatten.compact.map(&:uuid)

      # No pools given: empty map
      return {} if pool_uuids.empty?

      # No roles given: map all pools to nil
      return pool_uuids.each_with_object({}) { |uuid, hash| hash[uuid] = nil } if roles.empty?

      clue = client.get_clues(roles: roles, pool_uuids: pool_uuids, force_cache_miss: force_cache_miss)
    end

    #
    # Configuration
    #

    # Accessor for the fake client, which has some extra fake methods on it
    def new_fake_client
      new_client_call { FakeClient.new(configuration) }
    end

    def new_real_client
      new_client_call { RealClient.new(configuration) }
    end

    def new_local_query_client_with_fake
      new_client_call { LocalQueryClient.new(new_fake_client) }
    end

    def new_local_query_client_with_real
      new_client_call { LocalQueryClient.new(new_real_client) }
    end

    def use_real_client
      use_client_named(:real)
    end

    def use_fake_client
      use_client_named(:fake)
    end

    def use_client_named(client_name)
      RequestStore.store[:biglearn_v1_forced_client_in_use] = true
      self.client = new_client(client_name)
    end

    def default_client_name
      # The default Biglearn client is set via an admin console setting.  The
      # default value for this setting is environment-specific in config/initializers/
      # 02-settings.rb. Developers will need to use the admin console to change
      # the setting if they want during development.  During testing, devs can
      # use the `use_fake_client`, `use_real_client`, and `use_client_named`
      # methods.

      # We only read this setting once per request to prevent it from changing mid-request
      RequestStore.store[:biglearn_v1_default_client_name] ||= Settings::Biglearn.client
    end

    alias :threadsafe_client :client

    def client
      # We normally keep a cached version of the client in use.  If a caller
      # (normally a spec) has said to use a specific client, we don't want to
      # change the client. However if this is not the case and the client's
      # name no longer matches the admin DB setting, change it out.

      synchronize do
        if threadsafe_client.nil? ||
           (!RequestStore.store[:biglearn_v1_forced_client_in_use] &&
            threadsafe_client.name != default_client_name)
          self.client = new_client
          save_static_client!
        end
      end

      threadsafe_client
    end

    protected

    def new_configuration
      OpenStax::Biglearn::V1::Configuration.new
    end

    def new_client(name = default_client_name)
      case name
      when :local_query_with_fake
        new_local_query_client_with_fake
      when :local_query_with_real
        new_local_query_client_with_real
      when :real
        new_real_client
      when :fake
        new_fake_client
      else
        raise "Invalid client name (#{name}); don't know which Biglearn client to make"
      end
    end

    def new_client_call
      begin
        yield
      rescue StandardError => e
        raise "Biglearn client initialization error: #{e.message}"
      end
    end

  end

end
