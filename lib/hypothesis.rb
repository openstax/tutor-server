module Hypothesis
  def self.generate_grant_token(account)
      # openstax_uid is almost always present except for some fake accounts,
      # in which case we fall back to the account's uuid
      user_id = "acct:" + (account.openstax_uid || account.uuid).abs.to_s + "@openstax.org"

      payload = {
        aud: Rails.application.secrets.hypothesis[:host],
        iss: Rails.application.secrets.hypothesis[:client_id] || '',
        sub: user_id
      }
      JWT.encode payload, Rails.application.secrets.hypothesis[:client_secret] || '', 'HS256'
  end

end
