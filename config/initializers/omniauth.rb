secrets = Rails.application.secrets['salesforce']

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :salesforce, secrets['consumer_key'], secrets['consumer_secret']#, {:scope => "id api refresh_token"}
end

OmniAuth.config.logger = Rails.logger

# http://stackoverflow.com/a/11461558/1664216
# https://github.com/intridea/omniauth/wiki/FAQ
OmniAuth.config.on_failure = Proc.new { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
