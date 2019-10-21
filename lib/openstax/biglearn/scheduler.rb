require_relative './scheduler/configuration'
require_relative './scheduler/fake_client'
require_relative './scheduler/real_client'

module OpenStax::Biglearn::Scheduler
  include OpenStax::Biglearn::Interface

  MAX_ECOSYSTEM_MATRIX_REQUESTS = 10
  MAX_STUDENTS_PER_REQUEST = 1000

  class << self
    # student is a CourseMembership::Models::Student
    # task is a Tasks::Models::Task

    # Retrieves the scheduler calculation that will be used next
    # for the given student or that has been used for the given task
    # Requests is an array of hashes containing one or both of the following keys:
    # :student and :task
    def fetch_algorithm_exercise_calculations(*requests)
      scheduler_requests = requests.map do |request|
        student = request[:student]&.to_model
        task = request[:task]&.to_model
        raise MalformedRequest if student.nil? && task.nil?

        {}.tap do |scheduler_request|
          scheduler_request[:student] = student unless student.nil?
          scheduler_request[:task] = task unless task.nil?
        end
      end

      bulk_api_request(
        method: :fetch_algorithm_exercise_calculations,
        requests: scheduler_request,
        keys: [:student, :task]
      )
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

    def bulk_api_request(method:, requests:, keys:, result_class: Hash, uuid_key: :request_uuid)
      req = [requests].flatten

      return requests.is_a?(Array) ? [] : {} if req.empty?

      requests_map = {}
      req.each do |request|
        uuid = request.fetch uuid_key, SecureRandom.uuid

        requests_map[uuid] = verify_and_slice_request method: method, request: request, keys: keys
      end

      requests_array = requests_map.map do |uuid, request|
        request.has_key?(uuid_key) ? request : request.merge(uuid_key => uuid)
      end
      request_uuids = requests_map.keys.sort

      responses = OpenStax::Biglearn::Scheduler.client.public_send(
        method, requests: requests_array
      )

      responses_map = {}
      responses.each do |response|
        uuid = response[uuid_key]
        original_request = requests_map[uuid]
        accepted = accepted_responses_uuids.include? uuid

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
