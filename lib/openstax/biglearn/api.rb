require_relative './api/configuration'
require_relative './api/malformed_request'
require_relative './api/result_type_error'
require_relative './api/exercises_error'
require_relative './api/fake_client'
require_relative './api/real_client'

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

    # Adds the given ecosystem to Biglearn
    # Requests is a hash containing the following key: :ecosystem
    def create_ecosystem(request)
      single_api_request method: :create_ecosystem, request: request, keys: :ecosystem
    end

    # Adds the given course to Biglearn
    # Requests is a hash containing the following keys: :course and :ecosystem
    def create_course(request)
      single_api_request method: :create_course, request: request, keys: [:course, :ecosystem]
    end

    # Prepares Biglearn for a course ecosystem update
    # Requests is a hash containing the following keys: :course and :ecosystem
    # Returns a preparation_uuid to be used in the call to update_course_ecosystems
    def prepare_course_ecosystem(request)
      SecureRandom.uuid.tap do |preparation_uuid|
        single_api_request method: :prepare_course_ecosystem,
                           request: request.merge(preparation_uuid: preparation_uuid),
                           keys: [:course, :ecosystem]
      end
    end

    # Finalizes course ecosystem updates in Biglearn,
    # causing it to stop computing CLUes for the old one
    # Requests are hashes containing the following key: :preparation_uuid
    # Returns a hash mapping request objects to their update status (Symbol)
    def update_course_ecosystems(requests)
      bulk_api_request(method: :update_course_ecosystems,
                       requests: requests,
                       keys: :preparation_uuid,
                       result_class: Symbol) do |request, response|
        response[:update_status]
      end
    end

    # Updates Course rosters in Biglearn
    # Requests are hashes containing the following key: :course
    def update_rosters(requests)
      courses = [requests].flatten.map do |request|
        request[:course].tap do |course|
          course.lock! if course.persisted?
        end
      end

      bulk_api_request(method: :update_rosters, requests: requests, keys: :course).tap do
        courses.each do |course|
          course.sequence_number += 1
          course.save!(validate: false) if course.persisted?
        end
      end
    end

    # Updates global exercise exclusions
    # Request is a hash containing the following key: :exercise_ids
    def update_global_exercise_exclusions(request)
      single_api_request method: :update_global_exercise_exclusions,
                         request: request,
                         keys: :exercise_ids
    end

    # Updates exercise exclusions for the given course
    # Request is a hash containing the following key: :course
    def update_course_exercise_exclusions(request)
      single_api_request method: :update_course_exercise_exclusions,
                         request: request,
                         keys: :course
    end

    # Creates or updates tasks in Biglearn
    # Requests are hashes containing the following key: :task
    # The record's
    def create_update_assignments(requests)
      tasks = [requests].flatten.map do |request|
        request[:task].tap do |task|
          task.lock! if task.persisted?
        end
      end

      bulk_api_request(method: :create_update_assignments,
                       requests: requests,
                       keys: :task).tap do
        tasks.each do |task|
          task.sequence_number += 1
          task.save!(validate: false) if task.persisted?
        end
      end
    end

    # Returns a number of recommended personalized exercises for the given tasks
    # May return less than the given number if there aren't enough exercises
    # Requests are hashes containing the following keys: :task and :max_exercises_to_return
    # Returns a hash mapping request objects to Content::Models::Exercises
    def fetch_assignment_pes(requests)
      bulk_api_request(
        method: :fetch_assignment_pes,
        requests: requests,
        keys: [:task, :max_exercises_to_return],
        result_class: Content::Exercise
      ) do |request, response|
        get_exercises_by_tutor_uuids tutor_uuids: response[:exercise_uuids],
                                     max_exercises_to_return: request[:max_exercises_to_return]
      end
    end

    # Returns a number of recommended spaced practice exercises for the given tasks
    # May return less than the given number if there aren't enough exercises
    # Requests are hashes containing the following keys: :task and :max_exercises_to_return
    # Returns a hash mapping request objects to Content::Models::Exercises
    def fetch_assignment_spes(requests)
      bulk_api_request(
        method: :fetch_assignment_spes,
        requests: requests,
        keys: [:task, :max_exercises_to_return],
        result_class: Content::Exercise
      ) do |request, response|
        get_exercises_by_tutor_uuids tutor_uuids: response[:exercise_uuids],
                                     max_exercises_to_return: request[:max_exercises_to_return]
      end
    end

    # Returns a number of recommended personalized exercises for the student's worst topics
    # May return less than the given number if there aren't enough exercises
    # Requests are hashes containing the following keys: :student and :max_exercises_to_return
    # Returns a hash mapping request objects to Content::Models::Exercises
    def fetch_practice_worst_areas_pes(requests)
      bulk_api_request(
        method: :fetch_practice_worst_areas_pes,
        requests: requests,
        keys: [:student, :max_exercises_to_return],
        result_class: Content::Exercise
      ) do |request, response|
        get_exercises_by_tutor_uuids tutor_uuids: response[:exercise_uuids],
                                     max_exercises_to_return: request[:max_exercises_to_return]
      end
    end

    # Returns the CLUes for the given book containers and students (for students)
    # Requests are hashes containing the following keys: :book_container and :student
    # Returns a hash mapping request objects to a CLUe hash
    def fetch_student_clues(requests)
      bulk_api_request(method: :fetch_student_clues,
                       requests: requests,
                       keys: [:book_container, :student]) do |request, response|
        response[:clue_data]
      end
    end

    # Returns the CLUes for the given book containers and periods (for teachers)
    # Requests are hashes containing the following keys: :book_container and :course_container
    # Returns a hash mapping request objects to a CLUe hash
    def fetch_teacher_clues(requests)
      bulk_api_request(method: :fetch_teacher_clues,
                       requests: requests,
                       keys: [:book_container, :course_container]) do |request, response|
        response[:clue_data]
      end
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

    def use_real_client
      use_client new_real_client
    end

    def use_fake_client
      use_client new_fake_client
    end

    def use_client(client)
      RequestStore.store[:biglearn_v1_forced_client_in_use] = true
      self.client = client
    end

    def default_client_name
      # The default Biglearn client is set via an admin console setting. The
      # default value for this setting is environment-specific in config/initializers/
      # 02-settings.rb. Developers will need to use the admin console to change
      # the setting if they want during development. During testing, devs can
      # use the `use_fake_client` and `use_real_client` methods.

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

    def verify_and_slice_request(method:, request:, keys:)
      keys_array = [keys].flatten

      missing_keys = keys_array.reject{ |key| request.has_key? key }

      raise(
        OpenStax::Biglearn::Api::MalformedRequest,
        "Invalid request: #{method} request #{request.inspect
        } is missing these key(s): #{missing_keys.inspect}"
      ) if missing_keys.any?

      request.slice(*keys_array)
    end

    def verify_result(result:, result_class: Hash)
      results_array = [result].flatten

      results_array.each do |result|
        raise(
          OpenStax::Biglearn::Api::ResultTypeError,
          "Invalid result: #{result} has type #{result.class.name
          } but expected type was #{result_class.name}"
        ) if result.class != result_class
      end

      result
    end

    def single_api_request(method:, request:, keys:, result_class: Hash)
      verified_request = verify_and_slice_request method: method, request: request, keys: keys

      response = client.send(method, verified_request)

      verify_result(result: block_given? ? yield(request, response) : response,
                    result_class: result_class)
    end

    def bulk_api_request(method:, requests:, keys:, result_class: Hash)
      requests_map = {}
      [requests].flatten.map do |request|
        requests_map[SecureRandom.uuid] = verify_and_slice_request method: method,
                                                                   request: request,
                                                                   keys: keys
      end

      requests_array = requests_map.map{ |uuid, request| request.merge request_uuid: uuid }

      responses = {}
      client.send(method, requests_array).each do |response|
        request = requests_map[response[:request_uuid]]

        responses[request] = verify_result(
          result: block_given? ? yield(request, response) : response, result_class: result_class
        )
      end

      # If given a Hash instead of an Array, return the response directly
      requests.is_a?(Hash) ? responses.values.first : responses
    end

    def get_exercises_by_tutor_uuids(tutor_uuids:, max_exercises_to_return:)
      number_returned = tutor_uuids.length

      raise(OpenStax::Biglearn::Api::ExercisesError,
            "Biglearn returned more exercises than requested") \
        if number_returned > max_exercises_to_return

      Rails.logger.warn do
        "Biglearn returned less exercises than requested (#{
        number_returned} instead of #{max_exercises_to_return})"
      end if number_returned < max_exercises_to_return

      exercises = Content::Models::Exercise.where(tutor_uuid: tutor_uuids)
                                           .first(max_exercises_to_return)

      raise(OpenStax::Biglearn::Api::ExercisesError,
            "Biglearn returned exercises not present locally") \
        if exercises.length < number_returned

      exercises.map{ |exercise| Content::Exercise.new strategy: exercise.wrap }
    end

  end

end
