redis_secrets = Rails.application.secrets['redis']

Lev.configure do |config|
  config.raise_fatal_errors = false
  config.status_store = Lev::RedisStore.new(
    url: redis_secrets['url'],
    namespace: redis_secrets['namespaces']['lev']
  )
end
