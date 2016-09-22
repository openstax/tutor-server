require_relative './api/configuration'
require_relative './api/fake_client'
require_relative './api/real_client'
require_relative './api/local_clue'
require_relative './api/local_query_client'

module OpenStax::Biglearn::Api

  extend Configurable
  extend Configurable::ClientMethods
  extend MonitorMixin

  class << self

    #
    # API Wrappers
    #

    # Adds the given Content::Ecosystem to Biglearn
    def create_ecosystem(ecosystem:)
      client.create_ecosystem(ecosystem: ecosystem)
    end

    # Prepares Biglearn for Course Ecosystem updates
    # Updates is an array of { course: Entity::Course, ecosystem: Content::Ecosystem }
    def prepare_course_ecosystems(updates:)
      client.prepare_course_ecosystems(updates: updates)
    end

    # Finalizes a Course Ecosystem update in Biglearn,
    # causing it to stop computing CLUes for the old one
    def update_course_ecosystem(course:)
      client.update_course_ecosystem(course: course)
    end

    # Updates Course rosters in Biglearn
    # Updates is an array of {
    #   period: CourseMembership::Period,
    #   student: CourseMembership::Models::Student,
    #   action: 'add' OR 'remove'
    # }
    def update_rosters(updates:)
      client.update_rosters(updates: updates)
    end

    # Creates or updates an Assignment (Task) in Biglearn
    def create_or_update_assignment(assignment:)
      client.create_or_update_assignment(assignment: assignment)
    end

    # Returns a number of recommended exercises for the given Assignment (Task)
    # May return less than the given number if there aren't enough exercises
    def fetch_assignment_pes(assignment:, max_exercises_to_return:)
      client.fetch_assignment_pes(assignment: assignment,
                                  max_exercises_to_return: max_exercises_to_return)
    end

    # Returns a number of recommended exercises for the given Student and Book Container
    # Book Container is a Content::Chapter or Content::Page
    # May return less than the given number if there aren't enough exercises
    def fetch_topic_pes(student:, book_container:, max_exercises_to_return:)
      client.fetch_topic_pes(student: student, book_container: book_container,
                             max_exercises_to_return: max_exercises_to_return)
    end

    # Returns a number of recommended exercises for the given Student and Ecosystem
    # May return less than the given number if there aren't enough exercises
    def fetch_weakest_topics_pes(student:, ecosystem:, max_exercises_to_return:)
      client.fetch_weakest_topics_pes(student: student, ecosystem: ecosystem,
                                      max_exercises_to_return: max_exercises_to_return)
    end

    # Returns the CLUes for the given students
    def fetch_learner_clues(student:, ecosystem:, max_exercises_to_return:)
      client.fetch_weakest_topics_pes(student: student, ecosystem: ecosystem,
                                      max_exercises_to_return: max_exercises_to_return)
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
      OpenStax::Biglearn::Api::Configuration.new
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
