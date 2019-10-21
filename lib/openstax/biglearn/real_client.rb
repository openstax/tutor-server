class OpenStax::Biglearn::RealClient
  HEADER_OPTIONS = { 'Content-Type' => 'application/json' }.freeze

  def initialize(api_configuration)
    @server_url   = api_configuration.server_url
    @token        = api_configuration.token
    @client_id    = api_configuration.client_id
    @secret       = api_configuration.secret

    @oauth_client = OAuth2::Client.new @client_id, @secret, site: @server_url

    @oauth_token  = @oauth_client.client_credentials.get_token unless @client_id.nil?
  end

  def name
    :real
  end

  protected

  def token_header
    raise NotImplementedError
  end

  def absolutize_url(url)
    Addressable::URI.join @server_url, url.to_s
  end

  def api_request(method:, url:, body:)
    absolute_uri = absolutize_url(url)

    header_options = { headers: @token.nil? ? HEADER_OPTIONS : HEADER_OPTIONS.merge(
        token_header => @token
      )
    }
    request_options = body.nil? ? header_options : header_options.merge(body: body.to_json)

    response = (@oauth_token || @oauth_client).request method, absolute_uri, request_options

    JSON.parse(response.body).deep_symbolize_keys
  end

  def single_api_request(method: :post, url:, request:)
    response_hash = api_request method: method, url: url, body: request

    block_given? ? yield(response_hash) : response_hash
  end

  def bulk_api_request(method: :post, url:, requests:,
                       requests_key:, responses_key:, max_requests: 1000)
    max_requests ||= requests.size

    requests.each_slice(max_requests).flat_map do |requests|
      body = { requests_key => requests }

      response_hash = api_request method: method, url: url, body: body

      responses_array = response_hash[responses_key] || []

      responses_array.map { |response| block_given? ? yield(response) : response }
    end
  end
end
