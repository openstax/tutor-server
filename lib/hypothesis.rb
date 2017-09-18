module Hypothesis
  def self.generate_grant_token
      now = Time.now.to_i
      user_id = "acct:#{current_user.account_uuid}@openstax.org"

      payload = {
        aud: Rails.application.secrets[:hypothesis]['client_url'],
        iss: Rails.application.secrets[:hypothesis]['client_id'],
        sub: user_id,
        nbf: now,
        exp: now + 600
      }
      JWT.encode payload,
      Rails.application.secrets[:hypothesis]['client_secret'], 'HS256'
  end

end

