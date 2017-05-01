require_relative './api/configuration'
require_relative './api/job'
require_relative './api/job_failed'
require_relative './api/malformed_request'
require_relative './api/result_type_error'
require_relative './api/exercises_error'
require_relative './api/fake_client'
require_relative './api/real_client'

module OpenStax::Biglearn::Api

  MAX_CONTAINERS_PER_COURSE = 100
  MAX_STUDENTS_PER_COURSE = 1000

  OPTION_KEYS = [ :perform_later, :retry_proc, :inline_max_retries, :inline_sleep_interval ]

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
      request, options = extract_options request, true

      with_unique_gapless_ecosystem_sequence_numbers(requests: request, create: true) do |request|
        raise 'Attempted to create Ecosystem in Biglearn twice' if request[:sequence_number] > 0

        single_api_request options.merge(
          method: :create_ecosystem,
          request: { ecosystem: request[:ecosystem].to_model },
          keys: :ecosystem
        )
      end
    end

    # Creates or updates the given course in Biglearn,
    # including ecosystem and roster (if roster update was skipped before)
    # Request is a hash containing the following key: :course
    def prepare_and_update_course_ecosystem(*request)
      request, options = extract_options request, true

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
          create_course(options.merge course: course, ecosystem: ecosystem).tap do
            # Apply global exercise exclusions to the new course
            update_globally_excluded_exercises(options.merge course: course)

            # These calls exist in case we held off on them previously due to having no ecosystems
            update_rosters(options.merge course: course)
            update_course_active_dates(options.merge course: course)
          end
        else
          current_ecosystem = course.course_ecosystems.first.ecosystem

          # Course already exists in Biglearn, so just send the latest update
          preparation_uuid = prepare_course_ecosystem(
            options.merge course: course, ecosystem: current_ecosystem
          ).fetch(:preparation_uuid)

          update_course_ecosystems(options.merge course: course, preparation_uuid: preparation_uuid)
        end
      end
    end

    # Adds the given course to Biglearn
    # Requests is a hash containing the following keys: :course and :ecosystem
    def create_course(*request)
      request, options = extract_options request, true

      with_unique_gapless_course_sequence_numbers(requests: request, create: true) do |request|
        raise 'Attempted to create Course in Biglearn twice' if request[:sequence_number] > 0

        single_api_request options.merge(
          method: :create_course,
          request: request,
          keys: [:course, :ecosystem]
        )
      end
    end

    # Prepares Biglearn for a course ecosystem update
    # Requests is a hash containing the following keys: :course and :ecosystem
    # Returns a preparation_uuid to be used in the call to update_course_ecosystems
    def prepare_course_ecosystem(*request)
      request, options = extract_options request, true

      with_unique_gapless_course_sequence_numbers(requests: request) do |request|
        preparation_uuid = SecureRandom.uuid

        single_api_request options.merge(
          method: :prepare_course_ecosystem,
          request: request.merge(preparation_uuid: preparation_uuid),
          keys: [:preparation_uuid, :course, :sequence_number, :ecosystem]
        )

        { preparation_uuid: preparation_uuid }
      end
    end

    # Finalizes course ecosystem updates in Biglearn,
    # causing it to stop computing CLUes for the old one
    # Requests are hashes containing the following keys: :course and :preparation_uuid
    # Returns a hash mapping request objects to their update status (Symbol)
    def update_course_ecosystems(*requests)
      requests, options = extract_options requests, true

      with_unique_gapless_course_sequence_numbers(requests: requests) do |requests|
        bulk_api_request options.merge(
          method: :update_course_ecosystems,
          requests: requests,
          keys: [:course, :sequence_number, :preparation_uuid]
        )
      end
    end

    # Updates Course rosters in Biglearn
    # Requests are hashes containing the following key: :course
    # Requests will not be sent if the course has not been created in Biglearn due to no ecosystem
    def update_rosters(*requests)
      requests, options = extract_options requests, true

      select_proc = ->(request) do
        course = request.fetch(:course)

        num_course_containers = 0
        num_students = 0
        course.periods_with_deleted.each do |period|
          num_course_containers += 1
          num_students += period.latest_enrollments.length
        end

        if num_course_containers > MAX_CONTAINERS_PER_COURSE
          Rails.logger.error do
            "Course #{course.name} has #{num_course_containers} containers," +
            " which is more than the Biglearn API limit of #{MAX_CONTAINERS_PER_COURSE} containers"
          end

          false
        elsif num_students > MAX_STUDENTS_PER_COURSE
          Rails.logger.error do
            "Course #{course.name} has #{num_students} students," +
            " which is more than the Biglearn API limit of #{MAX_STUDENTS_PER_COURSE} students"
          end

          false
        else
          true
        end
      end

      with_unique_gapless_course_sequence_numbers(
        requests: requests, select_proc: select_proc
      ) do |requests|
        bulk_api_request options.merge(
          method: :update_rosters,
          requests: requests,
          keys: [:course, :sequence_number]
        )
      end
    end

    # Updates global exercise exclusions
    # Request is a hash containing the following key: :course
    def update_globally_excluded_exercises(*request)
      request, options = extract_options request, true

      with_unique_gapless_course_sequence_numbers(requests: request) do |request|
        single_api_request options.merge(
          method: :update_globally_excluded_exercises,
          request: request,
          keys: [:course, :sequence_number]
        )
      end
    end

    # Updates exercise exclusions for the given course
    # Request is a hash containing the following key: :course
    def update_course_excluded_exercises(*request)
      request, options = extract_options request, true

      with_unique_gapless_course_sequence_numbers(requests: request) do |request|
        single_api_request options.merge(
          method: :update_course_excluded_exercises,
          request: request,
          keys: [:course, :sequence_number]
        )
      end
    end

    # Updates the given course's start/end dates
    # Request is a hash containing the following key: :course
    def update_course_active_dates(*request)
      request, options = extract_options request, true

      with_unique_gapless_course_sequence_numbers(requests: request) do |request|
        single_api_request options.merge(
          method: :update_course_active_dates,
          request: request,
          keys: [:course, :sequence_number]
        )
      end
    end

    # Creates or updates tasks in Biglearn
    # Requests are hashes containing the following keys: :course and :task
    # They may also contain the following optional key: :core_page_ids
    # The task records' sequence numbers are increased by 1
    def create_update_assignments(*requests)
      requests, options = extract_options requests, true

      select_proc = ->(request) do
        task = request.fetch(:task)

        # Skip tasks with no ecosystem or not assigned to any student
        ecosystem = task.ecosystem
        student = task.taskings.first.try!(:role).try!(:student)

        ecosystem.present? && student.present?
      end

      with_unique_gapless_course_sequence_numbers(
        requests: requests, select_proc: select_proc
      ) do |requests|
        bulk_api_request options.merge(
          method: :create_update_assignments,
          requests: requests,
          keys: [:course, :sequence_number, :task],
          optional_keys: :core_page_ids
        )
      end
    end

    # Records a student's response for a given exercise
    # Requests are hashes containing the following keys: :course and :tasked_exercise
    def record_responses(*requests)
      requests, options = extract_options requests, true

      with_unique_gapless_course_sequence_numbers(requests: requests) do |requests|
        bulk_api_request options.merge(
          method: :record_responses,
          requests: requests,
          keys: [:course, :sequence_number, :tasked_exercise],
          uuid_key: :response_uuid
        )
      end
    end

    # Returns a number of recommended personalized exercises for the given tasks
    # May return less than the given number if there aren't enough exercises
    # Requests are hashes containing the following key: :task
    # They may also contain the following optional key: :max_num_exercises
    # Returns a hash mapping request objects to Content::Models::Exercises
    def fetch_assignment_pes(*requests)
      requests, options = extract_options requests, false

      bulk_api_request(
        options.merge(
          method: :fetch_assignment_pes,
          requests: requests,
          keys: :task,
          optional_keys: :max_num_exercises,
          result_class: Content::Exercise
        )
      ) do |request, response|
        get_ecosystem_exercises_by_uuids ecosystem: request[:task].ecosystem,
                                         exercise_uuids: response[:exercise_uuids],
                                         max_num_exercises: request[:max_num_exercises]
      end
    end

    # Returns a number of recommended spaced practice exercises for the given tasks
    # May return less than the given number if there aren't enough exercises
    # Requests are hashes containing the following keys: :task
    # They may also contain the following optional key: :max_num_exercises
    # Returns a hash mapping request objects to Content::Models::Exercises
    def fetch_assignment_spes(*requests)
      requests, options = extract_options requests, false

      bulk_api_request(
        options.merge(
          method: :fetch_assignment_spes,
          requests: requests,
          keys: :task,
          optional_keys: :max_num_exercises,
          result_class: Content::Exercise
        )
      ) do |request, response|
        get_ecosystem_exercises_by_uuids ecosystem: request[:task].ecosystem,
                                         exercise_uuids: response[:exercise_uuids],
                                         max_num_exercises: request[:max_num_exercises]
      end
    end

    # Returns a number of recommended personalized exercises for the student's worst topics
    # May return less than the given number if there aren't enough exercises
    # Requests are hashes containing the following keys: :student
    # They may also contain the following optional key: :max_num_exercises
    # Returns a hash mapping request objects to Content::Models::Exercises
    def fetch_practice_worst_areas_exercises(*requests)
      requests, options = extract_options requests, false

      bulk_api_request(
        options.merge(
          method: :fetch_practice_worst_areas_exercises,
          requests: requests,
          keys: :student,
          optional_keys: :max_num_exercises,
          result_class: Content::Exercise
        )
      ) do |request, response|
        get_ecosystem_exercises_by_uuids ecosystem: request[:student].course.ecosystems.first,
                                         exercise_uuids: response[:exercise_uuids],
                                         max_num_exercises: request[:max_num_exercises]
      end
    end

    # Returns the CLUes for the given book containers and students (for students)
    # Requests are hashes containing the following keys: :book_container and :student
    # Returns a hash mapping request objects to a CLUe hash
    def fetch_student_clues(*requests)
      requests, options = extract_options requests, false

      bulk_api_request(
        options.merge(
          method: :fetch_student_clues,
          requests: requests,
          keys: [:book_container, :student]
        )
      ) do |request, response|
        response.fetch :clue_data
      end
    end

    # Returns the CLUes for the given book containers and periods (for teachers)
    # Requests are hashes containing the following keys: :book_container and :course_container
    # Returns a hash mapping request objects to a CLUe hash
    def fetch_teacher_clues(*requests)
      requests, options = extract_options requests, false

      bulk_api_request(
        options.merge(
          method: :fetch_teacher_clues,
          requests: requests,
          keys: [:book_container, :course_container]
        )
      ) do |request, response|
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

    def single_api_request(method:, request:, keys:, optional_keys: [], result_class: Hash,
                           retry_proc: nil, perform_later: false,
                           inline_max_retries: 10, inline_sleep_interval: 1.second)
      verified_request = verify_and_slice_request method: method,
                                                  request: request,
                                                  keys: keys,
                                                  optional_keys: optional_keys

      if perform_later
        OpenStax::Biglearn::Api::Job.perform_later method.to_s, verified_request, retry_proc
      else
        should_retry = false
        for ii in 0..inline_max_retries do
          response = client.send(method, verified_request)

          should_retry = !retry_proc.nil? && retry_proc.call(response)
          break unless should_retry

          sleep(inline_sleep_interval)
        end

        Rails.logger.warn do
          "Maximum number of attempts exceeded when calling Biglearn API inline" +
          " - API: #{method} - Request: #{request}" +
          " - Attempts: #{ii + 1} - Sleep Interval: #{sleep_interval} second(s)"
        end if should_retry

        return verify_result(
          result: block_given? ? yield(request, response) : response, result_class: result_class
        ) if retry_proc.nil? || !retry_proc.call(response)
      end
    end

    def bulk_api_request(method:, requests:, keys:, optional_keys: [], result_class: Hash,
                         uuid_key: :request_uuid, retry_proc: nil, perform_later: false,
                         inline_max_retries: 10, inline_sleep_interval: 1.second)
      requests_map = {}
      [requests].flatten.each do |request|
        uuid = request.fetch(uuid_key, SecureRandom.uuid)

        requests_map[uuid] = verify_and_slice_request(
          method: method, request: request, keys: keys, optional_keys: optional_keys
        )
      end

      requests_with_uuids_map = requests_map.map do |uuid, request|
        request_with_uuid = request.has_key?(uuid_key) ? request : request.merge(uuid_key => uuid)

        [uuid, request_with_uuid]
      end.to_h
      requests_array = requests_with_uuids_map.values

      if perform_later
        OpenStax::Biglearn::Api::Job.perform_later method.to_s, requests_array, retry_proc
      else
        responses = {}
        for ii in 0..inline_max_retries do
          client.send(method, requests_array).each do |response|
            uuid = response[uuid_key]
            original_request = requests_map[uuid]

            if retry_proc.nil? || !retry_proc.call(response)
              responses[original_request] = verify_result(
                result: block_given? ? yield(original_request, response) : response,
                result_class: result_class
              )

              requests_with_uuids_map.delete uuid
            end
          end

          break if requests_with_uuids_map.empty?

          sleep(inline_sleep_interval)
        end

        Rails.logger.warn do
          "Maximum number of attempts exceeded when calling Biglearn API inline" +
          " - API: #{method} - Request(s): #{requests_with_uuids_map.values.inspect}" +
          " - Attempts: #{ii + 1} - Sleep Interval: #{inline_sleep_interval} second(s)"
        end unless requests_with_uuids_map.empty?

        # If given a Hash instead of an Array, return the response directly
        requests.is_a?(Hash) ? responses.values.first : responses
      end
    end

    def get_ecosystem_exercises_by_uuids(ecosystem:, exercise_uuids:, max_num_exercises:)
      number_returned = exercise_uuids.length
      exercises = ecosystem.exercises.where(uuid: exercise_uuids)

      raise(
        OpenStax::Biglearn::Api::ExercisesError, "Biglearn returned exercises not present locally"
      ) if exercises.count < number_returned

      unless max_num_exercises.nil?
        raise(
          OpenStax::Biglearn::Api::ExercisesError, "Biglearn returned more exercises than requested"
        ) if number_returned > max_num_exercises

        Rails.logger.warn do
          "Biglearn returned less exercises than requested (#{
          number_returned} instead of #{max_num_exercises})"
        end if number_returned < max_num_exercises

        exercises = exercises.first(max_num_exercises)
      end

      exercises.map { |exercise| Content::Exercise.new strategy: exercise.wrap }
    end

    # We attempt to make these wrappers as fast as possible
    # because it prevents any Biglearn calls that share the Course/Ecosystem's sequence_number
    # for the remaining duration of the transaction
    def with_unique_gapless_course_sequence_numbers(requests:, create: false,
                                                    select_proc: nil, &block)
      table_name = CourseProfile::Models::Course.table_name

      req = [requests].flatten

      req = req.select(&select_proc) unless select_proc.nil?

      # Any requests that get this far MUST be sent to biglearn-api
      # or else they will introduce gaps in the sequence_number
      # If aborting a request after this point is required in the future,
      # we will need to introduce a NO-OP CourseEvent in biglearn-api

      course_ids = req.map{ |request| request[:course].id }.compact
      course_id_counts = {}
      course_ids.each do |course_id|
        course_id_counts[course_id] = (course_id_counts[course_id] || 0) + 1
      end

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

    def extract_options(args_array, default_perform_later)
      default_hash = { perform_later: default_perform_later }

      num_args = args_array.size
      requests = args_array.first

      case num_args
      when 1
        case requests
        when Hash
          options = requests
          requests = requests.except(*OPTION_KEYS)
        when Array
          options = requests.last.is_a?(Hash) ? requests.last : {}
          last_request = options.except(*OPTION_KEYS)
          requests = requests[0..-2]
          requests << last_request unless last_request.blank?
        else
          options = {}
        end
      when 2
        options = args_array.last
      else
        raise ArgumentError, "wrong number of arguments (#{num_args} for 1..2)", caller
      end

      [requests, default_hash.merge(options.slice(*OPTION_KEYS))]
    end

  end

end
