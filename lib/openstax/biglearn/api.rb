require_relative './api/configuration'
require_relative './api/malformed_request'
require_relative './api/result_type_error'
require_relative './api/exercises_error'
require_relative './api/fake_client'
require_relative './api/real_client'

module OpenStax::Biglearn::Api

  MAX_CONTAINERS_PER_COURSE = 100
  MAX_STUDENTS_PER_COURSE = 1000

  OPTION_KEYS = [
    :response_status_key,
    :accepted_response_status,
    :inline_max_attempts,
    :inline_sleep_interval
  ]

  extend Configurable
  extend Configurable::ClientMethods
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
      request, options = extract_options request

      single_api_request options.merge(
        method: :create_ecosystem,
        request: { ecosystem: request[:ecosystem].to_model },
        keys: :ecosystem,
        create: true,
        perform_later: true,
        sequence_number_model_key: :ecosystem,
        sequence_number_model_class: Content::Models::Ecosystem
      )
    end

    # Creates or updates the given course in Biglearn,
    # including ecosystem and roster (if roster update was skipped before)
    # Request is a hash containing the following key: :course
    def prepare_and_update_course_ecosystem(*request)
      request, options = extract_options request

      course = request[:course]

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

    # Adds the given course to Biglearn
    # Requests is a hash containing the following keys: :course and :ecosystem
    def create_course(*request)
      request, options = extract_options request

      single_api_request options.merge(
        method: :create_course,
        request: request,
        keys: [:course, :ecosystem],
        create: true,
        perform_later: true,
        sequence_number_model_key: :course,
        sequence_number_model_class: CourseProfile::Models::Course
      )
    end

    # Prepares Biglearn for a course ecosystem update
    # Requests is a hash containing the following keys: :course and :ecosystem
    # Returns a preparation_uuid to be used in the call to update_course_ecosystems
    def prepare_course_ecosystem(*request)
      request, options = extract_options request

      preparation_uuid = SecureRandom.uuid

      single_api_request options.merge(
        method: :prepare_course_ecosystem,
        request: request.merge(preparation_uuid: preparation_uuid),
        keys: [:preparation_uuid, :course, :ecosystem],
        perform_later: true,
        sequence_number_model_key: :course,
        sequence_number_model_class: CourseProfile::Models::Course
      )

      { preparation_uuid: preparation_uuid }
    end

    # Finalizes course ecosystem updates in Biglearn,
    # causing it to stop computing CLUes for the old one
    # Requests are hashes containing the following keys: :course and :preparation_uuid
    # Returns a hash mapping request objects to their update status (Symbol)
    def update_course_ecosystems(*requests)
      requests, options = extract_options requests

      bulk_api_request options.merge(
        method: :update_course_ecosystems,
        requests: requests,
        keys: [:course, :preparation_uuid],
        perform_later: true,
        sequence_number_model_key: :course,
        sequence_number_model_class: CourseProfile::Models::Course,
        response_status_key: :update_status,
        accepted_response_status: [ 'updated_and_ready', 'updated_but_unready' ]
      )
    end

    # Updates Course rosters in Biglearn
    # Requests are hashes containing the following key: :course
    # Requests will not be sent if the course has not been created in Biglearn due to no ecosystem
    def update_rosters(*requests)
      requests, options = extract_options requests

      select_proc = ->(request) do
        course = request.fetch(:course)

        num_course_containers = 0
        num_students = 0
        course.periods_with_deleted.each do |period|
          num_course_containers += 1
          num_students += period.latest_enrollments_with_deleted.length
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
        elsif num_course_containers == 0
          # We simply cannot send roster updates for courses with 0 course_containers,
          # since biglearn-api requires at least 1 course_container in the request
          false
        else
          true
        end
      end

      bulk_api_request options.merge(
        method: :update_rosters,
        requests: requests,
        keys: [:course],
        select_proc: select_proc,
        perform_later: true,
        sequence_number_model_key: :course,
        sequence_number_model_class: CourseProfile::Models::Course
      )
    end

    # Updates global exercise exclusions
    # Request is a hash containing the following key: :course
    def update_globally_excluded_exercises(*request)
      request, options = extract_options request

      single_api_request options.merge(
        method: :update_globally_excluded_exercises,
        request: request,
        keys: [:course],
        perform_later: true,
        sequence_number_model_key: :course,
        sequence_number_model_class: CourseProfile::Models::Course
      )
    end

    # Updates exercise exclusions for the given course
    # Request is a hash containing the following key: :course
    def update_course_excluded_exercises(*request)
      request, options = extract_options request

      single_api_request options.merge(
        method: :update_course_excluded_exercises,
        request: request,
        keys: [:course],
        perform_later: true,
        sequence_number_model_key: :course,
        sequence_number_model_class: CourseProfile::Models::Course
      )
    end

    # Updates the given course's start/end dates
    # Request is a hash containing the following key: :course
    def update_course_active_dates(*request)
      request, options = extract_options request

      single_api_request options.merge(
        method: :update_course_active_dates,
        request: request,
        keys: [:course],
        perform_later: true,
        sequence_number_model_key: :course,
        sequence_number_model_class: CourseProfile::Models::Course
      )
    end

    # Creates or updates tasks in Biglearn
    # Requests are hashes containing the following keys: :course and :task
    # They may also contain the following optional key: :core_page_ids
    def create_update_assignments(*requests)
      requests, options = extract_options requests

      select_proc = ->(request) do
        task = request.fetch(:task)

        # Skip tasks with no ecosystem or not assigned to any student
        ecosystem = task.ecosystem
        student = task.taskings.first.try!(:role).try!(:student)

        ecosystem.present? && student.present?
      end

      bulk_api_request options.merge(
        method: :create_update_assignments,
        requests: requests,
        keys: [:course, :task],
        optional_keys: [:goal_num_tutor_assigned_pes, :goal_num_tutor_assigned_spes],
        perform_later: true,
        select_proc: select_proc,
        sequence_number_model_key: :course,
        sequence_number_model_class: CourseProfile::Models::Course
      )
    end

    # Records a student's response for a given exercise
    # Requests are hashes containing the following keys: :course and :tasked_exercise
    def record_responses(*requests)
      requests, options = extract_options requests

      bulk_api_request options.merge(
        method: :record_responses,
        requests: requests,
        keys: [:course, :tasked_exercise],
        uuid_key: :response_uuid,
        perform_later: true,
        sequence_number_model_key: :course,
        sequence_number_model_class: CourseProfile::Models::Course
      )
    end

    # Returns a number of recommended personalized exercises for the given tasks
    # May return less than the given number if there aren't enough exercises
    # Requests are hashes containing the following key: :task
    # They may also contain the following optional key: :max_num_exercises
    # Returns a hash mapping request objects to Content::Models::Exercises
    def fetch_assignment_pes(*requests)
      requests, options = extract_options requests

      bulk_api_request(
        options.merge(
          method: :fetch_assignment_pes,
          requests: requests,
          keys: :task,
          optional_keys: :max_num_exercises,
          perform_later: false,
          response_status_key: :assignment_status,
          accepted_response_status: 'assignment_ready'
        )
      ) do |request, response, accepted|
        # If no valid response was received from Biglearn, fallback to random personalized exercises
        {
          exercises: get_ecosystem_exercises_by_uuids(
            ecosystem: request[:task].ecosystem,
            exercise_uuids: response[:exercise_uuids],
            max_num_exercises: request[:max_num_exercises],
            accepted: accepted,
            task: request[:task]
          ),
          spy_info: response.fetch(:spy_info, {})
        }
      end
    end

    # Returns a number of recommended spaced practice exercises for the given tasks
    # May return less than the given number if there aren't enough exercises
    # Requests are hashes containing the following keys: :task
    # They may also contain the following optional key: :max_num_exercises
    # Returns a hash mapping request objects to Content::Models::Exercises
    def fetch_assignment_spes(*requests)
      requests, options = extract_options requests

      bulk_api_request(
        options.merge(
          method: :fetch_assignment_spes,
          requests: requests,
          keys: :task,
          optional_keys: :max_num_exercises,
          perform_later: false,
          response_status_key: :assignment_status,
          accepted_response_status: 'assignment_ready'
        )
      ) do |request, response, accepted|
        # If no valid response was received from Biglearn, fallback to random personalized exercises
        {
          exercises: get_ecosystem_exercises_by_uuids(
            ecosystem: request[:task].ecosystem,
            exercise_uuids: response[:exercise_uuids],
            max_num_exercises: request[:max_num_exercises],
            accepted: accepted,
            task: request[:task]
          ),
          spy_info: response.fetch(:spy_info, {})
        }
      end
    end

    # Returns a number of recommended personalized exercises for the student's worst topics
    # May return less than the given number if there aren't enough exercises
    # Requests are hashes containing the following keys: :student
    # They may also contain the following optional key: :max_num_exercises
    # Returns a hash mapping request objects to Content::Models::Exercises
    def fetch_practice_worst_areas_exercises(*requests)
      requests, options = extract_options requests

      bulk_api_request(
        options.merge(
          method: :fetch_practice_worst_areas_exercises,
          requests: requests,
          keys: :student,
          optional_keys: :max_num_exercises,
          perform_later: false,
          response_status_key: :student_status,
          accepted_response_status: 'student_ready'
        )
      ) do |request, response, _|
        # Return the last response received from Biglearn regardless of what it was
        {
          exercises: get_ecosystem_exercises_by_uuids(
            ecosystem: request[:student].course.ecosystems.first,
            exercise_uuids: response[:exercise_uuids],
            max_num_exercises: request[:max_num_exercises]
          ),
          spy_info: response.fetch(:spy_info, {})
        }
      end
    end

    # Returns the CLUes for the given book containers and students (for students)
    # Requests are hashes containing the following keys: :book_container and :student
    # Returns a hash mapping request objects to a CLUe hash
    def fetch_student_clues(*requests)
      requests, options = extract_options requests

      bulk_api_request(
        options.merge(
          method: :fetch_student_clues,
          requests: requests,
          keys: [:book_container, :student],
          perform_later: false
        )
      ) do |_, response, _|
        # Return the last response received from Biglearn regardless of what it was
        response.fetch :clue_data
      end
    end

    # Returns the CLUes for the given book containers and periods (for teachers)
    # Requests are hashes containing the following keys: :book_container and :course_container
    # Returns a hash mapping request objects to a CLUe hash
    def fetch_teacher_clues(*requests)
      requests, options = extract_options requests

      bulk_api_request(
        options.merge(
          method: :fetch_teacher_clues,
          requests: requests,
          keys: [:book_container, :course_container],
          perform_later: false
        )
      ) do |_, response, _|
        # Return the last response received from Biglearn regardless of what it was
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
      RequestStore.store[:biglearn_api_default_client_name] ||=
        Settings::Biglearn.client_name.to_sym
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

    def client_class(name: default_client_name)
      name_sym = name.to_sym

      case name_sym
      when :real
        RealClient
      when :fake
        FakeClient
      else
        valid_client_name = name_sym.to_s.include?('real') ? :real : :fake

        Rails.logger.error do
          "Invalid Biglearn client name: #{name_sym}. Setting it to #{valid_client_name}."
        end

        Settings::Biglearn.client_name = valid_client_name
        RequestStore.store[:biglearn_api_default_client_name] = valid_client_name

        client_class(name: valid_client_name)
      end
    end

    def new_client(name: default_client_name)
      begin
        client_class(name: name).new(configuration)
      rescue StandardError => e
        raise "Biglearn client initialization error: #{e.message}"
      end
    end

    def verify_and_slice_request(method:, request:, keys:, optional_keys: [])
      required_keys = [keys].flatten
      missing_keys = required_keys.reject { |key| request.has_key? key }

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

    # Any inline (perform_later: false) requests that require a sequence_number must either:
    # 1. Happen after the sequence_number increment has been committed to the DB
    #    in a background job that retries OR
    # 2. Happen right before the sequence_number increment is committed to the DB
    def single_api_request(method:, request:, keys:, optional_keys: [],
                           result_class: Hash, uuid_key: :request_uuid,
                           sequence_number_model_key: nil, sequence_number_model_class: nil,
                           create: false, perform_later: false,
                           response_status_key: nil, accepted_response_status: [],
                           inline_max_attempts: 30, inline_sleep_interval: 1.second)
      include_sequence_number = sequence_number_model_key.present? &&
                                sequence_number_model_class.present?

      job_class = include_sequence_number ? OpenStax::Biglearn::Api::JobWithSequenceNumber :
                                            OpenStax::Biglearn::Api::Job

      verified_request = verify_and_slice_request method: method,
                                                  request: request,
                                                  keys: keys,
                                                  optional_keys: optional_keys

      request_with_uuid = verified_request.has_key?(uuid_key) ?
                            verified_request :
                            verified_request.merge(uuid_key => SecureRandom.uuid)

      if perform_later
        job_class.perform_later method: method.to_s,
                                requests: request_with_uuid,
                                create: create,
                                sequence_number_model_key: sequence_number_model_key.to_s,
                                sequence_number_model_class: sequence_number_model_class.name,
                                response_status_key: response_status_key.try!(:to_s),
                                accepted_response_status: accepted_response_status
      else
        accepted = false
        inline_max_attempts.times do
          response = job_class.perform method: method,
                                       requests: request_with_uuid,
                                       create: create,
                                       sequence_number_model_key: sequence_number_model_key,
                                       sequence_number_model_class: sequence_number_model_class

          accepted = response_status_key.nil? ||
                     [accepted_response_status].flatten.include?(response[response_status_key])
          break if accepted

          sleep(inline_sleep_interval)
        end

        Rails.logger.warn do
          "Maximum number of attempts exceeded when calling Biglearn API inline" +
          " - API: #{method} - Request: #{request}" +
          " - Attempts: #{inline_max_attempts} - Sleep Interval: #{inline_sleep_interval} second(s)"
        end unless accepted

        verify_result(
          result: block_given? ? yield(request, response, accepted) : response,
          result_class: result_class
        )
      end
    end

    def bulk_api_request(method:, requests:, keys:, optional_keys: [],
                         result_class: Hash, uuid_key: :request_uuid, select_proc: nil,
                         sequence_number_model_key: nil, sequence_number_model_class: nil,
                         create: false, perform_later: false,
                         response_status_key: nil, accepted_response_status: [],
                         inline_max_attempts: 30, inline_sleep_interval: 1.second)
      include_sequence_numbers = sequence_number_model_key.present? &&
                                 sequence_number_model_class.present?

      job_class = include_sequence_numbers ? OpenStax::Biglearn::Api::JobWithSequenceNumber :
                                             OpenStax::Biglearn::Api::Job

      req = [requests].flatten
      req = req.select(&select_proc) unless select_proc.nil?

      return requests.is_a?(Array) ? [] : {} if req.empty?

      requests_map = {}
      req.each do |request|
        uuid = request.fetch(uuid_key, SecureRandom.uuid)

        requests_map[uuid] = verify_and_slice_request(
          method: method, request: request, keys: keys, optional_keys: optional_keys
        )
      end

      requests_array = requests_map.map do |uuid, request|
        request.has_key?(uuid_key) ? request : request.merge(uuid_key => uuid)
      end
      request_uuids = requests_map.keys.sort

      if perform_later
        job_class.perform_later method: method.to_s,
                                requests: requests_array,
                                create: create,
                                sequence_number_model_key: sequence_number_model_key.to_s,
                                sequence_number_model_class: sequence_number_model_class.name,
                                response_status_key: response_status_key.try!(:to_s),
                                accepted_response_status: accepted_response_status
      else
        responses = []
        accepted_responses_uuids = []
        all_accepted = false
        inline_max_attempts.times do
          responses = job_class.perform method: method,
                                        requests: requests_array,
                                        create: create,
                                        sequence_number_model_key: sequence_number_model_key,
                                        sequence_number_model_class: sequence_number_model_class

          accepted_response_status = [accepted_response_status].flatten \
            unless response_status_key.nil?

          accepted_responses_uuids = []
          responses.each do |response|
            accepted_responses_uuids << response[uuid_key] \
              if response_status_key.nil? ||
                 accepted_response_status.include?(response[response_status_key])
          end

          all_accepted = request_uuids == accepted_responses_uuids.sort!
          break if all_accepted

          sleep(inline_sleep_interval)
        end

        Rails.logger.warn do
          "Maximum number of attempts exceeded when calling Biglearn API inline" +
          " - API: #{method} - Request(s): #{requests_array.inspect}" +
          " - Attempts: #{inline_max_attempts} - Sleep Interval: #{inline_sleep_interval} second(s)"
        end unless all_accepted

        responses_map = {}
        responses.each do |response|
          uuid = response[uuid_key]
          original_request = requests_map[uuid]
          accepted = accepted_responses_uuids.include? uuid

          responses_map[original_request] = verify_result(
            result: block_given? ? yield(original_request, response, accepted) : response,
            result_class: result_class
          )
        end

        # If given a Hash instead of an Array, return the response directly
        requests.is_a?(Hash) ? responses_map.values.first : responses_map
      end
    end

    def get_ecosystem_exercises_by_uuids(
      ecosystem:, exercise_uuids:, max_num_exercises:, accepted: true, task: nil
    )
      if accepted
        exercises_by_uuid = ecosystem.exercises.where(uuid: exercise_uuids).index_by(&:uuid)
        ordered_exercises = exercise_uuids.map do |uuid|
          exercises_by_uuid[uuid].tap do |exercise|
            raise(
              OpenStax::Biglearn::Api::ExercisesError,
              "Biglearn returned exercises not present locally"
            ) if exercise.nil?
          end
        end

        unless max_num_exercises.nil?
          number_returned = exercise_uuids.length

          raise(
            OpenStax::Biglearn::Api::ExercisesError,
            "Biglearn returned more exercises than requested"
          ) if number_returned > max_num_exercises

          Rails.logger.warn do
            "Biglearn returned less exercises than requested (#{
            number_returned} instead of #{max_num_exercises})"
          end if number_returned < max_num_exercises

          ordered_exercises = ordered_exercises.first(max_num_exercises)
        end

        ordered_exercises.map { |exercise| Content::Exercise.new strategy: exercise.wrap }
      else
        # Fallback in case Biglearn fails to respond in a timely manner
        # We just assign personalized exercises for the current assignment
        # regardless of what the original slot was
        return [] if task.nil?

        course = task.taskings.first.try!(:role).try!(:student).try!(:course)
        return [] if course.nil?

        core_page_ids = task.task_steps.map(&:content_page_id).compact.uniq
        pages = ecosystem.pages.where(id: core_page_ids)
        if task.reading?
          pool_method = :reading_dynamic_pool
        elsif task.homework?
          pool_method = :homework_dynamic_pool
        else
          return []
        end
        pools = pages.map { |page| page.public_send(pool_method) }

        task_exercise_ids = Set.new task.tasked_exercises.pluck(:content_exercise_id)
        pool_exercises = pools.flat_map(&:exercises).uniq
        filtered_exercises = FilterExcludedExercises[exercises: pool_exercises, course: course]
        candidate_exercises = filtered_exercises.reject do |exercise|
          task_exercise_ids.include?(exercise.id)
        end

        candidate_exercises.sample(max_num_exercises).tap do |chosen_exercises|
          WarningMailer.log_and_deliver(
            "Assigned #{chosen_exercises.size} fallback personalized exercises for task with ID #{
            task.id} because Biglearn did not respond in a timely manner"
          ) unless chosen_exercises.empty?
        end
      end
    end

    def extract_options(args_array)
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

      [requests, options.slice(*OPTION_KEYS)]
    end

  end

end
