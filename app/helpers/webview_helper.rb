module WebviewHelper
  # Generates data for the FE to read as it boots up
  def bootstrap_data
    Api::V1::BootstrapDataRepresenter.new(current_user).to_json(
      user_options: {
        tutor_api_url: api_root_url,
        flash: flash.to_hash
      }
    )
  end

  def generate_hypothesis_token

    now = Time.now.to_i
    user_id = "acct:mike@openstax.org"

    payload = {
      aud: 'h.mikefromit.com',
      iss: Rails.application.secrets[:hypothesis]['client_id'],
      sub: user_id,
      nbf: now,
      exp: now + 600
    }
    JWT.encode payload, Rails.application.secrets[:hypothesis]['client_secret'], 'HS256'
  end
end
