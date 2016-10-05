class OpenStax::Biglearn::Api::RealClient

  HEADER_OPTIONS = { headers: { 'Content-Type' => 'application/json' } }.freeze

  def initialize(biglearn_configuration)
    @server_url   = biglearn_configuration.server_url
    @client_id    = biglearn_configuration.client_id
    @secret       = biglearn_configuration.secret

    @oauth_client = OAuth2::Client.new @client_id, @secret, site: @server_url

    @oauth_token  = @oauth_client.client_credentials.get_token unless @client_id.nil?
  end

  def name
    :real
  end

  #
  # API methods
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
  def create_ecosystem(request)
    single_api_request url: :create_ecosystem, request: biglearn_request
  end

  # Adds the given course to Biglearn
  def create_course(request)
    single_api_request url: :create_course, request: biglearn_request
  end

  # Prepares Biglearn for a course ecosystem update
  def prepare_course_ecosystem(request)
    single_api_request url: :prepare_course_ecosystem, request: biglearn_request
  end

  # Finalizes course ecosystem updates in Biglearn,
  # causing it to stop computing CLUes for the old one
  def update_course_ecosystems(requests)
    bulk_api_request url: :update_course_ecosystems, requests: biglearn_requests,
                     requests_key: :update_requests, responses_key: :update_responses
  end

  # Updates Course rosters in Biglearn
  def update_rosters(requests)
    bulk_api_request url: :update_rosters, requests: biglearn_requests,
                     requests_key: :rosters, responses_key: :updated_course_uuids, max_requests: 100
  end

  # Updates global exercise exclusions
  def update_global_exercise_exclusions(request)
    single_api_request url: :update_global_exercise_exclusions, request: request
  end

  # Updates exercise exclusions for the given course
  def update_course_exercise_exclusions(request)
    single_api_request url: :update_course_exercise_exclusions, request: biglearn_request
  end

  # Creates or updates tasks in Biglearn
  def create_update_assignments(requests)
    bulk_api_request url: :create_update_assignments, requests: biglearn_requests,
                     requests_key: :assignments, responses_key: :updated_assignments
  end

  # Returns a number of recommended personalized exercises for the given tasks
  def fetch_assignment_pes(requests)
    bulk_api_request url: :fetch_assignment_pes, requests: biglearn_requests,
                     requests_key: :pe_requests, responses_key: :pe_responses
  end

  # Returns a number of recommended spaced practice exercises for the given tasks
  def fetch_assignment_spes(requests)
    bulk_api_request url: :fetch_assignment_spes, requests: biglearn_requests,
                     requests_key: :spe_requests, responses_key: :spe_responses
  end

  # Returns a number of recommended personalized exercises for the student's worst topics
  def fetch_practice_worst_areas_pes(requests)
    bulk_api_request url: :fetch_practice_worst_areas_pes, requests: biglearn_requests,
                     requests_key: :worst_areas_requests, responses_key: :worst_areas_responses
  end

  # Returns the CLUes for the given book containers and students (for students)
  def fetch_student_clues(requests)
    bulk_api_request url: :fetch_student_clues, requests: biglearn_requests,
                     requests_key: :student_clue_requests, responses_key: :student_clue_responses
  end

  # Returns the CLUes for the given book containers and periods (for teachers)
  def fetch_teacher_clues(requests)
    bulk_api_request url: :fetch_student_clues, requests: biglearn_requests,
                     requests_key: :teacher_clue_requests, responses_key: :teacher_clue_responses
  end

  protected

  def absolutize_url(url)
    Addressable::URI.join @server_url, url.to_s
  end

  def single_api_request(method: :post, url:, request:)
    absolute_uri = absolutize_url(url)

    request_options = HEADER_OPTIONS.merge { body: request.to_json }

    response = (@oauth_token || @oauth_client).request method, absolute_uri, request_options

    response_hash = JSON.parse(response.body).deep_symbolize_keys

    block_given? ? yield(response_hash) : response_hash
  end

  def bulk_api_request(method: :post, url:, requests:,
                       requests_key:, responses_key:, max_requests: 1000)
    absolute_uri = absolutize_url(url)
    max_requests ||= requests.size

    requests.each_slice(max_requests) do |requests|
      requests_json = requests.map(&:to_json)

      request_options = HEADER_OPTIONS.merge { body: { requests_key => requests_json } }

      response = (@oauth_token || @oauth_client).request method, absolute_uri, request_options

      response_hashes = JSON.parse(response.body).deep_symbolize_keys[responses_key]

      response_hashes.map{ |response_hash| block_given? ? yield(response_hash) : response_hash }
    end
  end

end
