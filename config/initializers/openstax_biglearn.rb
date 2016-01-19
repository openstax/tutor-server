biglearn_secrets = Rails.application.secrets['openstax']['biglearn']
redis_secrets = Rails.application.secrets['redis']

OpenStax::Biglearn::V1.configure do |config|
  config.server_url = biglearn_secrets['url']
  config.client_id  = biglearn_secrets['client_id']
  config.secret     = biglearn_secrets['secret']
  config.fake_store = ActiveSupport::Cache::RedisStore.new(
    url: redis_secrets['url'],
    namespace: redis_secrets['namespaces']['fake_biglearn']
  )
end

# By default, stub unless in the production environment
stub = biglearn_secrets['stub'].nil? ? !Rails.env.production? : biglearn_secrets['stub']
stub ? OpenStax::Biglearn::V1.use_fake_client : OpenStax::Biglearn::V1.use_real_client
