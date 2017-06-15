class OpenStax::Payments::Api::RealClient

  HEADER_OPTIONS = { headers: { 'Content-Type' => 'application/json' } }.freeze

  def initialize(configuration)
    @server_url   = configuration.server_url
    @client_id    = configuration.client_id
    @secret       = configuration.secret

    @oauth_client = OAuth2::Client.new @client_id, @secret, site: @server_url

    @oauth_token  = @oauth_client.client_credentials.get_token unless @client_id.nil?
  end

  def name
    :real
  end

  #
  # API methods
  #

  def check_payment(product_instance_uuid:)
    api_request(method: :get, url: "/pay/check/#{uuid}")
  end

  protected

  def absolutize_url(url)
    Addressable::URI.join @server_url, url.to_s
  end

  def api_request(method:, url:, body:)
    absolute_uri = absolutize_url(url)

    request_options = HEADER_OPTIONS.merge({ body: body.to_json })

    response = (@oauth_token || @oauth_client).request method, absolute_uri, request_options

    JSON.parse(response.body).deep_symbolize_keys
  end

end
