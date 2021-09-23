class Lti::Platform < ApplicationRecord
  belongs_to :profile, subsystem: :user, optional: true, inverse_of: :lti_platforms

  has_many :users, inverse_of: :platform
  has_many :contexts, inverse_of: :platform
  has_many :resource_links, inverse_of: :platform

  validates :issuer, presence: true
  validates :client_id, presence: true
  validates :host, presence: true
  validates :jwks_endpoint, presence: true
  validates :authorization_endpoint, presence: true
  validates :token_endpoint, presence: true

  def private_key
    # TODO: Generate and store (one per platform?) public/private keypair(s)
    #       Make public key(s) available in a jwks endpoint that will be given to the LMS's
    OpenSSL::PKey::RSA.new 2048
  end

  # Platform-specific authorization token used by Lti::ResourceLink to request a scoped Bearer token
  def jwt_token
    current_time = Time.current

    JSON::JWT.new(
      iss: client_id,
      sub: client_id,
      aud: issuer,
      iat: current_time.to_i,
      exp: (current_time + 5.minutes).to_i,
      jti: SecureRandom.hex
    ).sign(private_key, :RS256)
  end
end
