class OpenStax::Payments::Api::RealClient

  HEADER_OPTIONS = { headers: { 'Content-Type' => 'application/json' } }.freeze

  def initialize(configuration)
    @server_url   = configuration.server_url
    @client_id    = configuration.client_id
    @secret       = configuration.secret
  end

  def name
    :real
  end

  #
  # API methods
  #

  def orders_for_account(account)
    api_request(method: :get, url: "/reporting/purchaser/#{account.uuid}.json")
  end

  def check_payment(product_instance_uuid:)
    api_request(method: :get, url: "/pay/check/#{product_instance_uuid}/")
  end

  def refund(product_instance_uuid:)
    api_request(method: :post, url: "/pay/refund/#{product_instance_uuid}/")
  end

  if !Rails.env.production?
    def make_fake_purchase(product_instance_uuid:)
      api_request(method: :post, url: "/pay/mock_purchase/#{product_instance_uuid}/")
    end
  end

  protected

  def oauth_worker
    # Lazily instantiate the oauth client and token primarily to ensure that
    # initialization does not occur before test code initialized (so that all
    # interactions are recorded inside VCR cassettes)

    @oauth_worker ||= begin
      @oauth_client = OAuth2::Client.new @client_id, @secret,
                                         site: @server_url, token_url: '/o/token/'

      @oauth_token  = @oauth_client.client_credentials.get_token unless @client_id.nil?

      @oauth_token || @oauth_client
    end
  end

  def absolutize_url(url)
    Addressable::URI.join @server_url, url.to_s
  end

  def api_request(method:, url:, body: {})
    absolute_uri = absolutize_url(url)

    request_options = HEADER_OPTIONS.merge({ body: body.to_json })

    begin
      response = oauth_worker.request method, absolute_uri, request_options
    rescue OAuth2::Error => err
      raise OpenStax::Payments::RemoteError
    end

    JSON.parse(response.body).deep_symbolize_keys
  end

end
