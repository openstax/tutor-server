module Hypothesis
  def self.generate_grant_token(account_uuid)
      now = Time.now.to_i
      user_id = "acct:" + account_uuid.abs.to_s + "@openstax.org"

      payload = {
        aud: Rails.application.secrets[:hypothesis]['host'],
        iss: Rails.application.secrets[:hypothesis]['client_id'] || '',
        sub: user_id,
        nbf: now,
        exp: now + 600
      }
      JWT.encode payload, Rails.application.secrets[:hypothesis]['client_secret'] || '', 'HS256'
  end

end
