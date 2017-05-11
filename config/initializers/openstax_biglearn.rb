biglearn_secrets = Rails.application.secrets['openstax']['biglearn']
redis_secrets = Rails.application.secrets['redis']

OpenStax::Biglearn::Api.configure do |config|
  config.server_url = biglearn_secrets['url']
  config.client_id  = biglearn_secrets['client_id']
  config.secret     = biglearn_secrets['secret']
  config.fake_store = ActiveSupport::Cache::RedisStore.new(
    url: redis_secrets['url'],
    namespace: redis_secrets['namespaces']['fake_biglearn']
  )
end
