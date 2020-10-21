sentry_secrets = Rails.application.secrets.sentry

Raven.configure do |config|
  config.dsn = sentry_secrets[:dsn]
  config.current_environment = Rails.application.secrets.environment_name

  # Send POST data and cookies to Sentry
  config.processors -= [ Raven::Processor::Cookies, Raven::Processor::PostData ]
  config.release = sentry_secrets[:release]
end
