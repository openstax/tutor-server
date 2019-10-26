class OpenStax::Biglearn::Sparfa::RealClient < OpenStax::Biglearn::RealClient
  # ecosystem_matrix_uuid is the UUID of an ecosystem matrix obtained from Biglearn Scheduler
  # students is an array of CourseMembership::Models::Student

  # Retrieves the SPARFA ecosystem matrix with the given ecosystem_matrix_uuid
  # optionally filtered to the given students
  # Requests is an array of hashes containing :ecosystem_matrix_uuid
  # and optionally :students and/or :responded_before
  def fetch_ecosystem_matrices(requests)
    sparfa_requests = requests.map do |request|
      request.slice(:request_uuid, :ecosystem_matrix_uuid, :responded_before).tap do |req|
        req[:student_uuids] = request[:students].map(&:uuid) unless request[:students].nil?
      end
    end

    bulk_api_request url: :fetch_ecosystem_matrices,
                     requests: sparfa_requests,
                     requests_key: :ecosystem_matrix_requests,
                     responses_key: :ecosystem_matrices
  end

  protected

  def token_header
    'Biglearn-Sparfa-Token'
  end
end
