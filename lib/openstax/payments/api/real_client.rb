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
    def make_fake_purchase(product_instance_uuid: nil, purchaser_account_uuid: nil)
      api_request(method: :post, url: "/pay/mock_purchase/", body: {
        product_instance_uuid: product_instance_uuid,
        purchaser_account_uuid: purchaser_account_uuid
      }.select{|k,v| !v.nil?})
    end
  end

  protected

  def oauth_worker
    # Lazily instantiate the oauth "worker" aka client/token primarily to ensure that
    # initialization does not occur before test code initialized (so that all
    # interactions are recorded inside VCR cassettes)

    if @oauth_worker.nil?
      initialize_oauth_variables!
    end
    @oauth_worker
  end

  def initialize_oauth_variables!
    @oauth_client = OAuth2::Client.new @client_id, @secret,
                                       site: @server_url, token_url: '/o/token/'

    @oauth_token  = @oauth_client.client_credentials.get_token unless @client_id.nil?

    @oauth_worker = @oauth_token || @oauth_client
  end

  def absolutize_url(url)
    Addressable::URI.join @server_url, url.to_s
  end

  def api_request(method:, url:, body: {})
    absolute_uri = absolutize_url(url)

    request_options = HEADER_OPTIONS.merge({ body: body.to_json })

    begin
      num_tries ||= 0
      num_tries += 1
      response = oauth_worker.request(method, absolute_uri, request_options)
    rescue OAuth2::Error => err
      if err.try(:response).try(:status) == 403
        # We will get a 403 when the keys aren't good or when the token has
        # expired.  (Or possibly for some other reason).  Since we can't control
        # if/when the token expires, try *once* to get a new token.  If we know
        # the token has expired, say as much in the log.  Since the token expiration
        # date can be changed on Payments without us knowing, we always try to get
        # a new token even if not expired.

        if num_tries >= 1
          Rails.logger.info("OX Payments: client token expired") if token_expired?
          Rails.logger.info("OX Payments: getting a new token to try to resolve a 403")
          initialize_oauth_variables! # resets token
          retry
        else
          Rails.logger.info("OX Payments: getting a new token didn't resolve the 403")
        end
      end

      raise OpenStax::Payments::RemoteError
    end

    JSON.parse(response.body).deep_symbolize_keys
  end

  def token_expired?
    expires_at = @oauth_token.try(:expires_at)
    return false if expires_at.nil?
    Time.now >= Time.at(expires_at)
  end

end
