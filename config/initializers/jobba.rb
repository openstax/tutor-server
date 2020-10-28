Jobba.configure do |config|
  redis_secrets = Rails.application.secrets.redis
  config.redis_options = { url: redis_secrets[:url] }
  config.namespace = redis_secrets[:namespaces][:jobba]
end
