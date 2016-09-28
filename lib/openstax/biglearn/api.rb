require_relative './api/configuration'
require_relative './api/malformed_request'
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

    # ecosystem is a Content::Ecosystem or Content::Models::Ecosystem
    # course is an Entity::Course
    # task is a Tasks::Models::Task
    # student is a CourseMembership::Models::Student
    # book_container is a Content::Chapter or Content::Page or one of their models
    # exercise_id is a String containing an Exercise uuid, number or uid
    # period is a CourseMembership::Period or CourseMembership::Models::Period
    # max_exercises_to_return is an integer

    # Adds the given ecosystems to Biglearn
    # Requests are hashes containing the following keys: :ecosystem
    def create_ecosystems(requests)
      api_request method: :create_ecosystems, requests: requests, keys: :ecosystem
    end

    # Prepares Biglearn for course ecosystem updates
    # Requests are hashes containing the following keys: :course and :ecosystem
    def prepare_course_ecosystems(requests)
      api_request method: :prepare_course_ecosystems,
                  requests: requests,
                  keys: [:course, :ecosystem]
    end

    # Finalizes a course ecosystem update in Biglearn,
    # causing it to stop computing CLUes for the old one
    # Requests are hashes containing the following key: :course
    def update_course_ecosystems(requests)
      api_request method: :update_course_ecosystems, requests: requests, keys: :course
    end

    # Updates Course rosters in Biglearn
    # Requests are hashes containing the following key: :course
    def update_rosters(requests)
      api_request method: :update_rosters, requests: requests, keys: :course
    end

    # Updates global exercise exclusions
    # Request is a hash containing the following key: :exercise_ids
    def update_global_exercise_exclusions(request)
      api_request method: :update_global_exercise_exclusions,
                  requests: request,
                  keys: :exercise_ids
    end

    # Updates exercise exclusions for the given courses
    # Requests are hashes containing the following key: :course
    def update_course_exercise_exclusions(requests)
      api_request method: :update_course_exercise_exclusions,
                  requests: requests,
                  keys: :course
    end

    # Creates or updates a task in Biglearn
    # Requests are hashes containing the following key: :task
    def create_or_update_assignments(requests)
      api_request method: :create_or_update_assignments,
                  requests: requests,
                  keys: :task
    end

    # Returns a number of recommended exercises for the given tasks
    # May return less than the given number if there aren't enough exercises
    # Requests are hashes containing the following keys: :task and :max_exercises_to_return
    def fetch_assignment_pes(requests)
      api_request method: :fetch_assignment_pes,
                  requests: requests,
                  keys: [:task, :max_exercises_to_return]
    end

    # Returns a number of recommended exercises for the given students and ecosystems
    # May return less than the given number if there aren't enough exercises
    # Requests are hashes containing the following keys:
    # :student, :ecosystem and max_exercises_to_return
    def fetch_weakest_topics_pes(requests)
      api_request method: :fetch_weakest_topics_pes,
                  requests: requests,
                  keys: [:student, :ecosystem, :max_exercises_to_return]
    end

    # Returns the CLUes for the given book containers and students
    # Requests are hashes containing the following keys: :book_container and :student
    def fetch_learner_clues(requests)
      api_request method: :fetch_learner_clues,
                  requests: requests,
                  keys: [:book_container, :student]
    end

    # Returns the CLUes for the given book containers and periods
    # Requests are hashes containing the following keys: :book_container and :period
    def fetch_teacher_clues(requests)
      api_request method: :fetch_teacher_clues,
                  requests: requests,
                  keys: [:book_container, :period]
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
      use_client(name: :real)
    end

    def use_fake_client
      use_client(name: :fake)
    end

    def use_client(name:)
      RequestStore.store[:biglearn_v1_forced_client_in_use] = true
      self.client = new_client(name: name)
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

    def new_client(name: default_client_name)
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

    def api_request(method:, requests:, keys:)
      keys_array = [keys].flatten

      requests_array = [requests].flatten.map do |request|
        missing_keys = keys_array.reject{ |key| request.has_key? key }

        raise(
          OpenStax::Biglearn::Api::MalformedRequest,
          "Invalid request: #{request.inspect} is missing these key(s): #{missing_keys.inspect}",
          caller
        ) if missing_keys.any?

        request.slice(*keys_array)
      end

      result = {}

      client.send(method, requests_array).each_with_index do |response, index|
        result[requests_array[index]] = response
      end

      # If given a Hash, we are in single request mode, so return the first and only response
      # Otherwise, return a hash or responses keyed by each request given
      requests.is_a?(Hash) ? result[requests] : result
    end

  end

end
