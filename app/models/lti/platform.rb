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

  # Platform-specific authorization token used by Lti::ResourceLink to request a scoped Bearer token
  def jwt_token
    current_time = Time.current

    JSON::JWT.new(
      iss: client_id,
      sub: client_id,
      aud: token_endpoint,
      iat: current_time.to_i,
      exp: (current_time + 5.minutes).to_i,
      jti: SecureRandom.hex
    ).sign(
      JSON::JWK.new(OpenSSL::PKey::RSA.new(Rails.application.secrets.lti[:private_key])), :RS256
    )
  end
end
