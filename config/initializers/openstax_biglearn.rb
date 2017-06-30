biglearn_api_secrets = Rails.application.secrets.openstax['biglearn']['api']
redis_secrets = Rails.application.secrets.redis

OpenStax::Biglearn::Api.configure do |config|
  config.server_url = biglearn_api_secrets['url']
  config.token      = biglearn_api_secrets['token']
  config.client_id  = biglearn_api_secrets['client_id']
  config.secret     = biglearn_api_secrets['secret']
  config.fake_store = ActiveSupport::Cache::RedisStore.new(
    url: redis_secrets['url'],
    namespace: redis_secrets['namespaces']['fake_biglearn']
  )
end
