# OmniAuth::Strategy::Options is the same as Hashie::Mash
class Lti::Options < OmniAuth::Strategy::Options
  attr_reader :strategy

  # The strategy finds the platform based on the issuer
  # OpenID Connect attempts to read options.issuer but in this case it should just match the params
  delegate :issuer, :platform, to: :strategy

  # These options are configured per-platform
  delegate :client_id, :host, :jwks_endpoint, :authorization_endpoint, to: :platform

  # Certain LTI parameters never change when compared to OpenID Connect. Those are set here.
  def initialize(options, strategy)
    super options.merge(
      name: :lti,
      discovery: false,
      client_auth_method: :jwks,
      scope: [ :openid ],
      response_type: :id_token,
      state: ->() { SecureRandom.hex },
      response_mode: :form_post,
      prompt: :none,
      send_scope_to_token_endpoint: true,
      uid_field: :sub
    )

    @strategy = strategy
  end

  def client_options
    OmniAuth::Strategy::Options.new(
      identifier: client_id,
      # TODO: Dynamically generate callback URL
      redirect_uri: "http://localhost:3001/auth/lti/callback?guid=760f4742-173b-498d-8abf-ef0778591cec",
      scheme: 'https',
      host: host,
      port: 443,
      jwks_uri: jwks_endpoint,
      authorization_endpoint: authorization_endpoint
    )
  end
end
