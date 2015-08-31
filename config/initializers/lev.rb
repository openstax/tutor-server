redis_secrets = Rails.application.secrets['redis']

Lev.configure do |config|
  config.raise_fatal_errors = false
  config.job_store = ActiveSupport::Cache::RedisStore.new(
    url: redis_secrets['url'],
    namespace: redis_secrets['namespaces']['lev'],
    expires_in: 1.week
  )
end
