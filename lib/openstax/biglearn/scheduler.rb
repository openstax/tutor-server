require_relative './scheduler/configuration'
require_relative './scheduler/fake_client'
require_relative './scheduler/real_client'

module OpenStax::Biglearn::Scheduler
  extend OpenStax::Biglearn::Interface

  class << self
    # student is a CourseMembership::Models::Student
    # task is a Tasks::Models::Task

    # Retrieves the scheduler calculation that would be used next
    # for the given student or that has been used for the given task
    # Requests is an array of hashes containing one or both of the following keys:
    # :student and :task
    def fetch_algorithm_exercise_calculations(*requests)
      requests, options = extract_options requests

      ecosystem_by_request = {}
      scheduler_requests = requests.map do |request|
        student = request[:student]
        task = request[:task]
        raise OpenStax::Biglearn::MalformedRequest if student.nil? && task.nil?

        request.slice(:algorithm_name).tap do |scheduler_request|
          scheduler_request[:student] = student unless student.nil?

          if task.nil?
            ecosystem_by_request[request] = student.course.ecosystems.first
          else
            ecosystem_by_request[request] = task.ecosystem
            scheduler_request[:task] = task
          end
        end
      end

      bulk_api_request(
        method: :fetch_algorithm_exercise_calculations,
        requests: scheduler_requests,
        keys: [ :algorithm_name ],
        optional_keys: [ :student, :task ]
      ) do |request, response|
        response[:calculations].map do |calculation|
          calculation.except(:exercise_uuids).merge(
            exercises: get_ecosystem_exercises_by_uuids(
              ecosystem: ecosystem_by_request[request], exercise_uuids: calculation[:exercise_uuids]
            )
          )
        end
      end
    end

    protected

    def new_configuration
      OpenStax::Biglearn::Scheduler::Configuration.new
    end

    def new_client
      client_class = configuration.stub ? OpenStax::Biglearn::Scheduler::FakeClient :
                                          OpenStax::Biglearn::Scheduler::RealClient

      begin
        client_class.new(configuration)
      rescue StandardError => e
        raise "Biglearn Scheduler client initialization error: #{e.message}"
      end
    end

    def bulk_api_request(method:, requests:, keys: [], optional_keys: [],
                         result_class: Hash, uuid_key: :request_uuid)
      req = [requests].flatten

      return requests.is_a?(Hash) ? nil : {} if req.empty?

      requests_map = {}
      req.each do |request|
        uuid = request.fetch uuid_key, SecureRandom.uuid

        requests_map[uuid] = verify_and_slice_request(
          method: method, request: request, keys: keys, optional_keys: optional_keys
        )
      end

      requests_array = requests_map.map do |uuid, request|
        request.has_key?(uuid_key) ? request : request.merge(uuid_key => uuid)
      end
      request_uuids = requests_map.keys.sort

      responses = OpenStax::Biglearn::Scheduler.client.public_send method, requests_array

      responses_map = {}
      responses.each do |response|
        original_request = requests_map[response[uuid_key]]

        responses_map[original_request] = verify_result(
          result: block_given? ? yield(original_request, response) : response,
          result_class: result_class
        )
      end

      # If given a Hash instead of an Array, return the response directly
      requests.is_a?(Hash) ? responses_map.values.first : responses_map
    end
  end
end
