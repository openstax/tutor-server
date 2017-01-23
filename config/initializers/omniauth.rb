secrets = Rails.application.secrets['salesforce']

client_options = secrets['login_site'] ? { site: secrets['login_site'] } : {}

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :salesforce,
           secrets['consumer_key'],
           secrets['consumer_secret'],
           client_options: client_options
end

OmniAuth.config.logger = Rails.logger

# http://stackoverflow.com/a/11461558/1664216
# https://github.com/intridea/omniauth/wiki/FAQ
OmniAuth.config.on_failure = Proc.new { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
