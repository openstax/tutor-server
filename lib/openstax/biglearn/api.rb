require_relative './api/configuration'
require_relative './api/client'
require_relative './api/fake_client'
require_relative './api/real_client'

module OpenStax::Biglearn::Api
  extend OpenStax::Biglearn::Interface

  MAX_CONTAINERS_PER_COURSE = 100
  MAX_STUDENTS_PER_COURSE = 1000

  OPTION_KEYS = [
    :response_status_key,
    :accepted_response_status,
    :inline_max_attempts,
    :inline_sleep_interval,
    :enable_warnings
  ]

  class << self
    # ecosystem is a Content::Models::Ecosystem or Content::Models::Ecosystem
    # course is a CourseProfile::Models::Course
    # task is a Tasks::Models::Task
    # student is a CourseMembership::Models::Student
    # book_container is a Content::Chapter or Content::Page or one of their models
    # exercise_id is a String containing an Exercise uuid, number or uid
    # period is a CourseMembership::Models::Period
    # max_num_exercises is an integer

    # Adds the given ecosystem to Biglearn
    # Request is a hash containing the following key: :ecosystem
    def create_ecosystem(*request)
      request, options = extract_options request, OPTION_KEYS

      single_api_request options.merge(
        method: :create_ecosystem,
        request: { ecosystem: request[:ecosystem] },
        keys: :ecosystem,
        create: true,
        sequence_number_model_key: :ecosystem,
        sequence_number_model_class: Content::Models::Ecosystem
      )
    end

    # Creates or updates the given course in Biglearn,
    # including ecosystem and roster (if roster update was skipped before)
    # Request is a hash containing the following key: :course
    def prepare_and_update_course_ecosystem(*request)
      request, options = extract_options request, OPTION_KEYS

      course = request[:course]
      course_ecosystems = course.course_ecosystems.to_a

      # Don't send course to Biglearn if it has no ecosystems
      return if course_ecosystems.empty?

      if course.sequence_number.nil? || course.sequence_number == 0
        # The initial ecosystem is always course_ecosystems.last
        ecosystem = course_ecosystems.last.ecosystem

        # New course, so create it in Biglearn
        create_course(options.merge course: course, ecosystem: ecosystem).tap do
          # Apply global exercise exclusions to the new course
          update_globally_excluded_exercises(options.merge course: course)

          # Apply course exercise exclusions to the new course if it has any (e.g. cloned courses)
          update_course_excluded_exercises(options.merge course: course) \
            if course.excluded_exercises.any?

          # These calls exist in case we held off on them previously due to having no ecosystems
          update_rosters(options.merge course: course)
          update_course_active_dates(options.merge course: course)
        end
      else
        # nil from_ecosystem should not happen in reality because we keep courses at
        # sequence_number == 0 until they receive their first ecosystem
        # but it does happen in testing, where courses are initialized with random sequence_numbers
        from_ecosystem = course_ecosystems.second.try! :ecosystem
        to_ecosystem = course_ecosystems.first.ecosystem

        # Course already exists in Biglearn, so just send the latest update
        sequentially_prepare_and_update_course_ecosystem(
          options.merge course: course, from_ecosystem: from_ecosystem, to_ecosystem: to_ecosystem
        )
      end
    end

    # Adds the given course to Biglearn
    # Requests is a hash containing the following keys: :course and :ecosystem
    def create_course(*request)
      request, options = extract_options request, OPTION_KEYS

      single_api_request options.merge(
        method: :create_course,
        request: request,
        keys: [:course, :ecosystem],
        create: true,
        sequence_number_model_key: :course,
        sequence_number_model_class: CourseProfile::Models::Course
      )
    end

    # Prepares Biglearn for a course ecosystem update
    # Requests is a hash containing the following keys: :course and :ecosystem
    # Returns a preparation_uuid to be used in the call to update_course_ecosystems
    def prepare_course_ecosystem(*request)
      request, options = extract_options request, OPTION_KEYS

      preparation_uuid = SecureRandom.uuid

      single_api_request options.merge(
        method: :prepare_course_ecosystem,
        request: request.merge(preparation_uuid: preparation_uuid),
        keys: [:preparation_uuid, :course, :from_ecosystem, :to_ecosystem],
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
      requests, options = extract_options requests, OPTION_KEYS

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

    # Executes prepare_course_ecosystem and update_course_ecosystems sequentially
    def sequentially_prepare_and_update_course_ecosystem(*request)
      request, options = extract_options request, OPTION_KEYS

      preparation_uuid = SecureRandom.uuid

      single_api_request options.merge(
        method: :sequentially_prepare_and_update_course_ecosystem,
        request: request.merge(preparation_uuid: preparation_uuid),
        keys: [:preparation_uuid, :course, :from_ecosystem, :to_ecosystem],
        sequence_number_model_key: :course,
        sequence_number_model_class: CourseProfile::Models::Course
      )

      { preparation_uuid: preparation_uuid }
    end

    # Updates Course rosters in Biglearn
    # Requests are hashes containing the following key: :course
    # Requests will not be sent if the course has not been created in Biglearn due to no ecosystem
    def update_rosters(*requests)
      requests, options = extract_options requests, OPTION_KEYS

      select_proc = ->(request) do
        course = request.fetch(:course)

        # The create_course event is not sent until the course has an ecosystem
        next false if course.ecosystems.empty?

        num_course_containers = 0
        num_students = 0
        course.periods.each do |period|
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
      request, options = extract_options request, OPTION_KEYS

      single_api_request options.merge(
        method: :update_globally_excluded_exercises,
        request: request,
        keys: [:course],
        sequence_number_model_key: :course,
        sequence_number_model_class: CourseProfile::Models::Course
      )
    end

    # Updates exercise exclusions for the given course
    # Request is a hash containing the following key: :course
    def update_course_excluded_exercises(*request)
      request, options = extract_options request, OPTION_KEYS

      single_api_request options.merge(
        method: :update_course_excluded_exercises,
        request: request,
        keys: [:course],
        sequence_number_model_key: :course,
        sequence_number_model_class: CourseProfile::Models::Course
      )
    end

    # Updates the given course's start/end dates
    # Request is a hash containing the following key: :course
    def update_course_active_dates(*request)
      request, options = extract_options request, OPTION_KEYS

      single_api_request options.merge(
        method: :update_course_active_dates,
        request: request,
        keys: [:course],
        sequence_number_model_key: :course,
        sequence_number_model_class: CourseProfile::Models::Course
      )
    end

    # Creates or updates tasks in Biglearn
    # Requests are hashes containing the following keys: :course and :task
    # They may also contain the following optional key: :core_page_ids
    def create_update_assignments(*requests)
      requests, options = extract_options requests, OPTION_KEYS

      select_proc = ->(request) do
        task = request.fetch(:task)

        # Skip tasks with no ecosystem or not assigned to anyone
        task.ecosystem.present? && task.taskings.first&.role&.course_member.present?
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
      requests, options = extract_options requests, OPTION_KEYS

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
      requests, options = extract_options requests, OPTION_KEYS

      bulk_api_request(
        options.merge(
          method: :fetch_assignment_pes,
          requests: requests,
          keys: :task,
          optional_keys: :max_num_exercises,
          perform_later: false,
          response_status_key: :assignment_status,
          accepted_response_status: 'assignment_ready',
          client: 'fake'
        )
      ) do |request, response, accepted|
        # If no valid response was received from Biglearn, fallback to random personalized exercises
        {
          accepted: accepted,
          exercises: get_ecosystem_exercises_by_uuids(
            ecosystem: request[:task].ecosystem,
            exercise_uuids: response[:exercise_uuids],
            max_num_exercises: request[:max_num_exercises],
            accepted: accepted,
            task: request[:task],
            enable_warnings: options[:enable_warnings]
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
      requests, options = extract_options requests, OPTION_KEYS

      bulk_api_request(
        options.merge(
          method: :fetch_assignment_spes,
          requests: requests,
          keys: :task,
          optional_keys: :max_num_exercises,
          perform_later: false,
          response_status_key: :assignment_status,
          accepted_response_status: 'assignment_ready',
          client: 'fake'
        )
      ) do |request, response, accepted|
        # If no valid response was received from Biglearn, fallback to random personalized exercises
        {
          accepted: accepted,
          exercises: get_ecosystem_exercises_by_uuids(
            ecosystem: request[:task].ecosystem,
            exercise_uuids: response[:exercise_uuids],
            max_num_exercises: request[:max_num_exercises],
            accepted: accepted,
            task: request[:task],
            enable_warnings: options[:enable_warnings]
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
      requests, options = extract_options requests, OPTION_KEYS

      bulk_api_request(
        options.merge(
          method: :fetch_practice_worst_areas_exercises,
          requests: requests,
          keys: :student,
          optional_keys: :max_num_exercises,
          perform_later: false,
          response_status_key: :student_status,
          accepted_response_status: 'student_ready',
          client: 'fake'
        )
      ) do |request, response, _|
        # Return the last response received from Biglearn regardless of what it was
        {
          exercises: get_ecosystem_exercises_by_uuids(
            ecosystem: request[:student].course.ecosystem,
            exercise_uuids: response[:exercise_uuids],
            max_num_exercises: request[:max_num_exercises],
            enable_warnings: options[:enable_warnings]
          ),
          spy_info: response.fetch(:spy_info, {})
        }
      end
    end

    # Returns the CLUes for the given book containers and students (for students)
    # Requests are hashes containing the following keys: :book_container and :student
    # Returns a hash mapping request objects to a CLUe hash
    def fetch_student_clues(*requests)
      requests, options = extract_options requests, OPTION_KEYS
      client = [ requests ].flatten.all? do |request|
        request[:student].course.is_preview
      end ? 'fake' : nil

      bulk_api_request(
        options.merge(
          method: :fetch_student_clues,
          requests: requests,
          keys: [:book_container_uuid, :student],
          perform_later: false,
          client: client
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
      requests, options = extract_options requests, OPTION_KEYS
      client = [ requests ].flatten.all? do |request|
        request[:course_container].course.is_preview
      end ? 'fake' : nil

      bulk_api_request(
        options.merge(
          method: :fetch_teacher_clues,
          requests: requests,
          keys: [:book_container_uuid, :course_container],
          perform_later: false,
          client: client
        )
      ) do |_, response, _|
        # Return the last response received from Biglearn regardless of what it was
        response.fetch :clue_data
      end
    end

    protected

    def new_configuration
      OpenStax::Biglearn::Api::Configuration.new
    end

    def new_fake_client
      begin
        OpenStax::Biglearn::Api::FakeClient.new(configuration)
      rescue StandardError => e
        raise "Biglearn API client initialization error: #{e.message}"
      end
    end

    def new_real_client
      begin
        OpenStax::Biglearn::Api::RealClient.new(configuration)
      rescue StandardError => e
        raise "Biglearn API client initialization error: #{e.message}"
      end
    end

    # Inline (perform_later: false) sequence_number requests are not recommended
    # because they may cause the entire current transaction to rollback,
    # depending on the transaction isolation settings
    def single_api_request(method:, request:, keys:, optional_keys: [],
                           result_class: Hash, uuid_key: :request_uuid,
                           sequence_number_model_key: nil, sequence_number_model_class: nil,
                           create: false, perform_later: true,
                           response_status_key: nil, accepted_response_status: [],
                           inline_max_attempts: 1, inline_sleep_interval: 0,
                           enable_warnings: true, client: nil)
      include_sequence_number = sequence_number_model_key.present? &&
                                sequence_number_model_class.present?

      verified_request = verify_and_slice_request method: method,
                                                  request: request,
                                                  keys: keys,
                                                  optional_keys: optional_keys

      request_with_uuid = verified_request.has_key?(uuid_key) ?
                            verified_request :
                            verified_request.merge(uuid_key => SecureRandom.uuid)

      args = {
        requests: request_with_uuid,
        create: create,
        client: client
      }

      job_class = if include_sequence_number
        is_preview = request[sequence_number_model_key.to_sym].try(:is_preview)
        args[:queue] = is_preview ? 'preview' : 'biglearn'
        args[:client] = 'fake' if client.nil? && is_preview

        OpenStax::Biglearn::Api::JobWithSequenceNumber
      else
        # :nocov:
        # No API call currently uses this branch of the code
        OpenStax::Biglearn::Api::Job
        # :nocov:
      end

      if perform_later
        args.merge! method: method.to_s,
                    sequence_number_model_key: sequence_number_model_key.to_s,
                    sequence_number_model_class: sequence_number_model_class.name,
                    response_status_key: response_status_key&.to_s,
                    accepted_response_status: accepted_response_status

        job_class.perform_later args
      else
        # :nocov:
        # No API call currently uses this branch of the code
        args.merge! method: method,
                    sequence_number_model_key: sequence_number_model_key,
                    sequence_number_model_class: sequence_number_model_class

        accepted = false
        inline_max_attempts.times do
          response = job_class.perform args

          accepted = response_status_key.nil? ||
                     [accepted_response_status].flatten.include?(response[response_status_key])
          break if accepted

          sleep(inline_sleep_interval)
        end

        Rails.logger.warn do
          "Maximum number of attempts exceeded when calling Biglearn API inline" +
          " - API: #{method} - Request: #{request}" +
          " - Attempts: #{inline_max_attempts} - Sleep Interval: #{inline_sleep_interval} second(s)"
        end if enable_warnings && !accepted

        verify_result(
          result: block_given? ? yield(request, response, accepted) : response,
          result_class: result_class
        )
        # :nocov:
      end
    end

    def bulk_api_request(method:, requests:, keys:, optional_keys: [],
                         result_class: Hash, uuid_key: :request_uuid, select_proc: nil,
                         sequence_number_model_key: nil, sequence_number_model_class: nil,
                         create: false, perform_later: false,
                         response_status_key: nil, accepted_response_status: [],
                         inline_max_attempts: 1, inline_sleep_interval: 0,
                         enable_warnings: true, client: nil)
      include_sequence_numbers = sequence_number_model_key.present? &&
                                 sequence_number_model_class.present?

      req = [requests].flatten
      req = req.select(&select_proc) unless select_proc.nil?

      return requests.is_a?(Hash) ? nil : {} if req.empty?

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

      args = {
        requests: requests_array,
        create: create,
        client: client
      }

      job_class = if include_sequence_numbers
        is_preview = requests.is_a?(Array) ? requests.all? do |request|
          request[sequence_number_model_key.to_sym].try(:is_preview)
        end : requests[sequence_number_model_key.to_sym].try(:is_preview)
        args[:queue] = is_preview ? 'preview' : 'biglearn'
        args[:client] = 'fake' if client.nil? && is_preview

        OpenStax::Biglearn::Api::JobWithSequenceNumber
      else
        OpenStax::Biglearn::Api::Job
      end

      if perform_later
        args.merge! method: method.to_s,
                    sequence_number_model_key: sequence_number_model_key.to_s,
                    sequence_number_model_class: sequence_number_model_class.name,
                    response_status_key: response_status_key&.to_s,
                    accepted_response_status: accepted_response_status

        job_class.perform_later args
      else
        args.merge! method: method,
                    sequence_number_model_key: sequence_number_model_key,
                    sequence_number_model_class: sequence_number_model_class

        responses = []
        accepted_responses_uuids = []
        all_accepted = false
        inline_max_attempts.times do
          responses = job_class.perform args

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
        end if enable_warnings && !all_accepted

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
  end
end
