require_relative './sparfa/configuration'
require_relative './sparfa/fake_client'
require_relative './sparfa/real_client'

module OpenStax::Biglearn::Sparfa
  extend OpenStax::Biglearn::Interface

  class << self
    # ecosystem_matrix_uuid is the UUID of an ecosystem matrix obtained from Biglearn Scheduler
    # students is an array of CourseMembership::Models::Student

    # Retrieves the SPARFA ecosystem matrix with the given ecosystem_matrix_uuid
    # optionally filtered to the given students
    # Requests is an array of hashes containing :ecosystem_matrix_uuid
    # and optionally :students and/or :responded_before
    def fetch_ecosystem_matrices(*requests)
      requests, options = extract_options requests

      sparfa_requests = requests.map do |request|
        students = request[:students]

        request.slice(:ecosystem_matrix_uuid, :responded_before).tap do |sparfa_request|
          sparfa_request[:students] = students.map(&:to_model) unless students.nil?
        end
      end

      bulk_api_request(
        method: :fetch_ecosystem_matrices,
        requests: sparfa_requests,
        keys: [ :ecosystem_matrix_uuid ],
        optional_keys: [ :students, :responded_before ]
      )
    end

    protected

    def new_configuration
      OpenStax::Biglearn::Sparfa::Configuration.new
    end

    def new_client
      client_class = configuration.stub ? OpenStax::Biglearn::Sparfa::FakeClient :
                                          OpenStax::Biglearn::Sparfa::RealClient

      begin
        client_class.new(configuration)
      rescue StandardError => e
        raise "Biglearn Sparfa client initialization error: #{e.message}"
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

      responses = OpenStax::Biglearn::Sparfa.client.public_send method, requests_array

      responses_map = {}
      responses.each do |response|
        uuid = response[uuid_key]
        original_request = requests_map[uuid]

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
