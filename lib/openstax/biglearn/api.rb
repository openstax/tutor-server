require_relative './api/configuration'
require_relative './api/job'
require_relative './api/malformed_request'
require_relative './api/result_type_error'
require_relative './api/exercises_error'
require_relative './api/fake_client'
require_relative './api/real_client'

module OpenStax::Biglearn::Api

  extend Configurable
  extend Configurable::ClientMethods
  extend OpenStax::Biglearn::Locks
  extend MonitorMixin

  class << self

    #
    # API Wrappers
    #

    # ecosystem is a Content::Ecosystem or Content::Models::Ecosystem
    # course is a CourseProfile::Models::Course
    # task is a Tasks::Models::Task
    # student is a CourseMembership::Models::Student
    # book_container is a Content::Chapter or Content::Page or one of their models
    # exercise_id is a String containing an Exercise uuid, number or uid
    # period is a CourseMembership::Period or CourseMembership::Models::Period
    # max_num_exercises is an integer

    # Adds the given ecosystem to Biglearn
    # Requests is a hash containing the following key: :ecosystem
    def create_ecosystem(*request)
      request, perform_later = extract_perform_later request

      with_unique_gapless_ecosystem_sequence_numbers(requests: request, create: true) do |request|
        raise 'Attempted to create Ecosystem in Biglearn twice' if request[:sequence_number] > 0

        single_api_request method: :create_ecosystem,
                           request: request.merge(ecosystem: request[:ecosystem].to_model),
                           keys: :ecosystem,
                           perform_later: perform_later
      end
    end

    # Creates or updates the given course in Biglearn,
    # including ecosystem and roster (if roster update was skipped before)
    # Requests is a hash containing the following key: :course
    def prepare_and_update_course_ecosystem(*request)
      request, perform_later = extract_perform_later request

      course = request[:course]

      with_course_locks(course.id) do
        # Reload after locking
        course.reload if course.persisted?

        # Don't send course to Biglearn if it has no ecosystems
        return if course.course_ecosystems.empty?

        if course.sequence_number.nil? || course.sequence_number == 0
          # The initial ecosystem is always course_ecosystems.last
          ecosystem = course.course_ecosystems.last.ecosystem

          # New course, so create it in Biglearn
          create_course(course: course, ecosystem: ecosystem, perform_later: perform_later).tap do
            # Apply global exercise exclusions to the new course
            update_globally_excluded_exercises(course: course, perform_later: perform_later)

            # These calls exist in case we held off on them previously due to having no ecosystems
            update_rosters(course: course, perform_later: perform_later)
            update_course_active_dates(course: course, perform_later: perform_later)
          end
        else
          current_ecosystem = course.course_ecosystems.first.ecosystem

          # Course already exists in Biglearn, so just send the latest update
          preparation_uuid = prepare_course_ecosystem(
            course: course, ecosystem: current_ecosystem, perform_later: perform_later
          ).fetch(:preparation_uuid)

          update_course_ecosystems(
            course: course, preparation_uuid: preparation_uuid, perform_later: perform_later
          )
        end
      end
    end

    # Adds the given course to Biglearn
    # Requests is a hash containing the following keys: :course and :ecosystem
    def create_course(*request)
      request, perform_later = extract_perform_later request

      with_unique_gapless_course_sequence_numbers(requests: request, create: true) do |request|
        raise 'Attempted to create Course in Biglearn twice' if request[:sequence_number] > 0

        single_api_request method: :create_course,
                           request: request,
                           keys: [:course, :ecosystem],
                           perform_later: perform_later
      end
    end

    # Prepares Biglearn for a course ecosystem update
    # Requests is a hash containing the following keys: :course and :ecosystem
    # Returns a preparation_uuid to be used in the call to update_course_ecosystems
    def prepare_course_ecosystem(*request)
      request, perform_later = extract_perform_later request

      with_unique_gapless_course_sequence_numbers(requests: request) do |request|
        preparation_uuid = SecureRandom.uuid

        single_api_request method: :prepare_course_ecosystem,
                           request: request.merge(preparation_uuid: preparation_uuid),
                           keys: [:course, :sequence_number, :ecosystem],
                           perform_later: perform_later

        { preparation_uuid: preparation_uuid }
      end
    end

    # Finalizes course ecosystem updates in Biglearn,
    # causing it to stop computing CLUes for the old one
    # Requests are hashes containing the following keys: :course and :preparation_uuid
    # Returns a hash mapping request objects to their update status (Symbol)
    def update_course_ecosystems(*requests)
      requests, perform_later = extract_perform_later requests

      with_unique_gapless_course_sequence_numbers(requests: requests) do |requests|
        bulk_api_request method: :update_course_ecosystems,
                         requests: requests,
                         keys: [:course, :sequence_number, :preparation_uuid],
                         perform_later: perform_later
      end
    end

    # Updates Course rosters in Biglearn
    # Requests are hashes containing the following key: :course
    # Requests will not be sent if the course has not been created in Biglearn due to no ecosystem
    def update_rosters(*requests)
      requests, perform_later = extract_perform_later requests

      with_unique_gapless_course_sequence_numbers(requests: requests) do |requests|
        bulk_api_request method: :update_rosters,
                         requests: requests,
                         keys: [:course, :sequence_number],
                         perform_later: perform_later
      end
    end

    # Updates global exercise exclusions
    # Request is a hash containing the following key: :course
    def update_globally_excluded_exercises(*request)
      request, perform_later = extract_perform_later request

      with_unique_gapless_course_sequence_numbers(requests: request) do |request|
        single_api_request method: :update_globally_excluded_exercises,
                           request: request,
                           keys: [:course, :sequence_number],
                           perform_later: perform_later
      end
    end

    # Updates exercise exclusions for the given course
    # Request is a hash containing the following key: :course
    def update_course_excluded_exercises(*request)
      request, perform_later = extract_perform_later request

      with_unique_gapless_course_sequence_numbers(requests: request) do |request|
        single_api_request method: :update_course_excluded_exercises,
                           request: request,
                           keys: [:course, :sequence_number],
                           perform_later: perform_later
      end
    end

    # Updates the given course's start/end dates
    # Request is a hash containing the following key: :course
    def update_course_active_dates(*request)
      request, perform_later = extract_perform_later request

      with_unique_gapless_course_sequence_numbers(requests: request) do |request|
        single_api_request method: :update_course_active_dates,
                           request: request,
                           keys: [:course, :sequence_number],
                           perform_later: perform_later
      end
    end

    # Creates or updates tasks in Biglearn
    # Requests are hashes containing the following keys: :course and :task
    # They may also contain the following optional key: :core_page_ids
    # The task records' sequence numbers are increased by 1
    def create_update_assignments(*requests)
      requests, perform_later = extract_perform_later requests

      with_unique_gapless_course_sequence_numbers(requests: requests) do |requests|
        bulk_api_request method: :create_update_assignments,
                         requests: requests,
                         keys: [:course, :sequence_number, :task],
                         optional_keys: :core_page_ids,
                         perform_later: perform_later
      end
    end

    # Records a student's response for a given exercise
    # Requests are hashes containing the following keys: :course and :tasked_exercise
    def record_responses(*requests)
      requests, perform_later = extract_perform_later requests

      with_unique_gapless_course_sequence_numbers(requests: requests) do |requests|
        bulk_api_request method: :record_responses,
                         requests: requests,
                         keys: [:course, :sequence_number, :tasked_exercise],
                         uuid_key: :response_uuid,
                         perform_later: perform_later
      end
    end

    # Returns a number of recommended personalized exercises for the given tasks
    # May return less than the given number if there aren't enough exercises
    # Requests are hashes containing the following keys: :task and :max_num_exercises
    # Returns a hash mapping request objects to Content::Models::Exercises
    def fetch_assignment_pes(requests)
      bulk_api_request(
        method: :fetch_assignment_pes,
        requests: requests,
        keys: [:task, :max_num_exercises],
        result_class: Content::Exercise
      ) do |request, response|
        get_ecosystem_exercises_by_uuids ecosystem: request[:task].ecosystem,
                                         exercise_uuids: response[:exercise_uuids],
                                         max_num_exercises: request[:max_num_exercises]
      end
    end

    # Returns a number of recommended spaced practice exercises for the given tasks
    # May return less than the given number if there aren't enough exercises
    # Requests are hashes containing the following keys: :task and :max_num_exercises
    # Returns a hash mapping request objects to Content::Models::Exercises
    def fetch_assignment_spes(requests)
      bulk_api_request(
        method: :fetch_assignment_spes,
        requests: requests,
        keys: [:task, :max_num_exercises],
        result_class: Content::Exercise
      ) do |request, response|
        get_ecosystem_exercises_by_uuids ecosystem: request[:task].ecosystem,
                                         exercise_uuids: response[:exercise_uuids],
                                         max_num_exercises: request[:max_num_exercises]
      end
    end

    # Returns a number of recommended personalized exercises for the student's worst topics
    # May return less than the given number if there aren't enough exercises
    # Requests are hashes containing the following keys: :student and :max_num_exercises
    # Returns a hash mapping request objects to Content::Models::Exercises
    def fetch_practice_worst_areas_exercises(requests)
      bulk_api_request(
        method: :fetch_practice_worst_areas_exercises,
        requests: requests,
        keys: [:student, :max_num_exercises],
        result_class: Content::Exercise
      ) do |request, response|
        get_ecosystem_exercises_by_uuids ecosystem: request[:student].course.ecosystems.first,
                                         exercise_uuids: response[:exercise_uuids],
                                         max_num_exercises: request[:max_num_exercises]
      end
    end

    # Returns the CLUes for the given book containers and students (for students)
    # Requests are hashes containing the following keys: :book_container and :student
    # Returns a hash mapping request objects to a CLUe hash
    def fetch_student_clues(requests)
      bulk_api_request(method: :fetch_student_clues,
                       requests: requests,
                       keys: [:book_container, :student]) do |request, response|
        response.fetch :clue_data
      end
    end

    # Returns the CLUes for the given book containers and periods (for teachers)
    # Requests are hashes containing the following keys: :book_container and :course_container
    # Returns a hash mapping request objects to a CLUe hash
    def fetch_teacher_clues(requests)
      bulk_api_request(method: :fetch_teacher_clues,
                       requests: requests,
                       keys: [:book_container, :course_container]) do |request, response|
        response.fetch :clue_data
      end
    end

    #
    # Configuration
    #

    def default_client_name
      # The default Biglearn client is set via an admin console setting. The
      # default value for this setting is environment-specific in config/initializers/
      # 02-settings.rb. Developers will need to use the admin console to change
      # the setting if they want during development.

      # We only read this setting once per request to prevent it from changing mid-request
      RequestStore.store[:biglearn_api_default_client_name] ||= Settings::Biglearn.client.to_sym
    end

    alias :threadsafe_client :client

    def client
      # We normally keep a cached version of the client in use.  If a caller
      # (normally a spec) has said to use a specific client, we don't want to
      # change the client. However if this is not the case and the client's
      # name no longer matches the admin DB setting, change it out.

      synchronize do
        if threadsafe_client.nil? || threadsafe_client.name != default_client_name
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
      client_class = case name.to_sym
      when :real
        RealClient
      when :fake
        FakeClient
      else
        raise "Invalid Biglearn client name (#{name})"
      end

      begin
        client_class.new(configuration)
      rescue StandardError => e
        raise "Biglearn client initialization error: #{e.message}"
      end
    end

    def verify_and_slice_request(method:, request:, keys:, optional_keys: [])
      required_keys = [keys].flatten
      missing_keys = required_keys.reject{ |key| request.has_key? key }

      raise(
        OpenStax::Biglearn::Api::MalformedRequest,
        "Invalid request: #{method} request #{request.inspect
        } is missing these required key(s): #{missing_keys.inspect}"
      ) if missing_keys.any?

      optional_keys = [optional_keys].flatten
      request_keys = required_keys + optional_keys

      request.slice(*request_keys)
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

    def single_api_request(method:, request:, keys:, optional_keys: [],
                           result_class: Hash, perform_later: false)
      verified_request = verify_and_slice_request method: method,
                                                  request: request,
                                                  keys: keys,
                                                  optional_keys: optional_keys

      if perform_later
        OpenStax::Biglearn::Api::Job.perform_later method.to_s, verified_request
      else
        response = client.send(method, verified_request)

        verify_result(result: block_given? ? yield(request, response) : response,
                      result_class: result_class)
      end
    end

    def bulk_api_request(method:, requests:, keys:, optional_keys: [],
                         result_class: Hash, uuid_key: :request_uuid, perform_later: false)
      requests_map = {}
      [requests].flatten.map do |request|
        requests_map[SecureRandom.uuid] = verify_and_slice_request method: method,
                                                                   request: request,
                                                                   keys: keys,
                                                                   optional_keys: optional_keys
      end

      requests_array = requests_map.map{ |uuid, request| request.merge uuid_key => uuid }

      if perform_later
        OpenStax::Biglearn::Api::Job.perform_later method.to_s, requests_array
      else
        responses = {}
        client.send(method, requests_array).each do |response|
          request = requests_map[response[uuid_key]]

          responses[request] = verify_result(
            result: block_given? ? yield(request, response) : response, result_class: result_class
          )
        end

        # If given a Hash instead of an Array, return the response directly
        requests.is_a?(Hash) ? responses.values.first : responses
      end
    end

    def get_ecosystem_exercises_by_uuids(ecosystem:, exercise_uuids:, max_num_exercises:)
      number_returned = exercise_uuids.length

      raise(
        OpenStax::Biglearn::Api::ExercisesError, "Biglearn returned more exercises than requested"
      ) if number_returned > max_num_exercises

      Rails.logger.warn do
        "Biglearn returned less exercises than requested (#{
        number_returned} instead of #{max_num_exercises})"
      end if number_returned < max_num_exercises

      exercises = ecosystem.exercises.where(uuid: exercise_uuids).first(max_num_exercises)

      raise(
        OpenStax::Biglearn::Api::ExercisesError, "Biglearn returned exercises not present locally"
      ) if exercises.length < number_returned

      exercises.map { |exercise| Content::Exercise.new strategy: exercise.wrap }
    end

    # We attempt to make these wrappers as fast as possible
    # because it prevents any Biglearn calls that share the Course/Ecosystem's sequence_number
    # for the remaining duration of the transaction
    def with_unique_gapless_course_sequence_numbers(requests:, create: false, &block)
      table_name = CourseProfile::Models::Course.table_name

      req = [requests].flatten

      course_id_counts = {}
      req.map{ |request| request[:course].id }.compact.each do |course_id|
        course_id_counts[course_id] = (course_id_counts[course_id] || 0) + 1
      end
      course_ids = course_id_counts.keys

      cases = course_id_counts.map do |course_id, count|
        "WHEN #{course_id} THEN #{count}"
      end
      increments = "CASE \"id\" #{cases.join(' ')} END"

      with_course_locks(course_ids) do
        # Update and read all sequence_numbers in one statement to minimize time waiting for I/O
        # Requests for courses that have not been created
        # on the Biglearn side (sequence_number == 0) are suppressed
        sequence_numbers_by_course_id = {}
        CourseProfile::Models::Course.connection.execute(
          "UPDATE #{table_name}" +
          " SET \"sequence_number\" = \"sequence_number\" + #{increments}" +
          " WHERE \"#{table_name}\".\"id\" IN (#{course_ids.join(', ')})" +
          " #{'AND "sequence_number" > 0' unless create}" +
          " RETURNING \"id\", \"sequence_number\""
        ).each do |hash|
          id = hash['id'].to_i
          sequence_numbers_by_course_id[id] = hash['sequence_number'].to_i - course_id_counts[id]
        end if course_ids.any?

        requests_with_sequence_numbers = req.map do |request|
          course = request[:course]

          if course.new_record?
            # Special case for unsaved records
            sequence_number = course.sequence_number || 0
            next if sequence_number == 0 && !create

            course.sequence_number = sequence_number + 1
            next request.merge(sequence_number: sequence_number)
          end


          sequence_number = sequence_numbers_by_course_id[course.id]
          # Requests for courses that have not been created
          # on the Biglearn side (sequence_number == 0) are suppressed
          next if sequence_number.nil?

          next_sequence_number = sequence_number + 1
          sequence_numbers_by_course_id[course.id] = next_sequence_number

          # Make sure the provided record model has the new sequence_number
          # and mark the attribute as persisted
          course.sequence_number = next_sequence_number
          course.previous_changes[:sequence_number] = course.changes[:sequence_number]
          course.send :clear_attribute_changes, :sequence_number

          # Call the given block with the previous sequence_number
          request.merge(sequence_number: sequence_number)
        end.compact

        # If an array was given, call the block with an array
        # If another type of argument was given, extract the block argument from the array
        modified_requests = requests.is_a?(Array) ? requests_with_sequence_numbers :
                                                    requests_with_sequence_numbers.first

        # nil can happen if the request got suppressed due to the course having no ecosystem
        block.call(modified_requests) unless modified_requests.nil?
      end
    end

    def with_unique_gapless_ecosystem_sequence_numbers(requests:, create: false, &block)
      table_name = Content::Models::Ecosystem.table_name

      req = [requests].flatten

      ecosystem_id_counts = {}
      req.map{ |request| request[:ecosystem].id }.compact.each do |ecosystem_id|
        ecosystem_id_counts[ecosystem_id] = (ecosystem_id_counts[ecosystem_id] || 0) + 1
      end
      ecosystem_ids = ecosystem_id_counts.keys

      cases = ecosystem_id_counts.map do |ecosystem_id, count|
        "WHEN #{ecosystem_id} THEN #{count}"
      end
      increments = "CASE \"id\" #{cases.join(' ')} END"

      with_ecosystem_locks(ecosystem_ids) do
        # Update and read all sequence_numbers in one statement to minimize time waiting for I/O
        # Requests for ecosystems that have not been created
        # on the Biglearn side (sequence_number == 0) are suppressed
        sequence_numbers_by_ecosystem_id = {}
        Content::Models::Ecosystem.connection.execute(
          "UPDATE #{table_name}" +
          " SET \"sequence_number\" = \"sequence_number\" + #{increments}" +
          " WHERE \"#{table_name}\".\"id\" IN (#{ecosystem_ids.join(', ')})" +
          " #{'AND "sequence_number" > 0' unless create}" +
          " RETURNING \"id\", \"sequence_number\""
        ).each do |hash|
          id = hash['id'].to_i
          sequence_numbers_by_ecosystem_id[id] = \
            hash['sequence_number'].to_i - ecosystem_id_counts[id]
        end if ecosystem_ids.any?

        requests_with_sequence_numbers = req.map do |request|
          ecosystem = request[:ecosystem].to_model

          if ecosystem.new_record?
            # Special case for unsaved records
            sequence_number = ecosystem.sequence_number || 0
            next if sequence_number == 0 && !create

            ecosystem.sequence_number = sequence_number + 1
            next request.merge(sequence_number: sequence_number)
          end


          sequence_number = sequence_numbers_by_ecosystem_id[ecosystem.id]
          # Requests for courses that have not been created
          # on the Biglearn side (sequence_number == 0) are suppressed
          next if sequence_number.nil?

          next_sequence_number = sequence_number + 1
          sequence_numbers_by_ecosystem_id[ecosystem.id] = next_sequence_number

          # Make sure the provided record model has the new sequence_number
          # and mark the attribute as persisted
          ecosystem.sequence_number = next_sequence_number
          ecosystem.previous_changes[:sequence_number] = ecosystem.changes[:sequence_number]
          ecosystem.send :clear_attribute_changes, :sequence_number

          # Call the given block with the previous sequence_number
          request.merge(sequence_number: sequence_number)
        end.compact

        # If an array was given, call the block with an array
        # If another type of argument was given, extract the block argument from the array
        modified_requests = requests.is_a?(Array) ? requests_with_sequence_numbers :
                                                    requests_with_sequence_numbers.first

        # nil can happen if the request got suppressed due to the course having no ecosystem
        block.call(modified_requests) unless modified_requests.nil?
      end
    end

    def extract_perform_later(args, default = true)
      if args.size == 1
        args = args.first

        case args
        when Array
          [args, default]
        when Hash
          [args.except(:perform_later), args.fetch(:perform_later, default)]
        else
          raise ArgumentError, caller
        end
      elsif args.size == 2
        [args.first, args.last.fetch(:perform_later, default)]
      else
        raise ArgumentError, caller
      end
    end

  end

end
