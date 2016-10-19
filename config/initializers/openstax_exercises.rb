secrets = Rails.application.secrets['openstax']['exercises']
redis_secrets = Rails.application.secrets['redis']

OpenStax::Exercises::V1.configure do |config|
  config.server_url = secrets['url']
  config.client_id  = secrets['client_id']
  config.secret     = secrets['secret']
  config.stub       = !!secrets['stub']
  config.fake_store = ActiveSupport::Cache::RedisStore.new(
    url: redis_secrets['url'],
    namespace: redis_secrets['namespaces']['fake_exercises']
  )
end
