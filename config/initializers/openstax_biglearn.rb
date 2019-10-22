biglearn_secrets = Rails.application.secrets.openstax[:biglearn]
redis_secrets = Rails.application.secrets.redis

biglearn_api_secrets = biglearn_secrets[:api]
OpenStax::Biglearn::Api.configure do |config|
  config.server_url = biglearn_api_secrets[:url]
  config.token = biglearn_api_secrets[:token]
  config.client_id = biglearn_api_secrets[:client_id]
  config.secret = biglearn_api_secrets[:secret]
  config.stub = ActiveAttr::Typecasting::BooleanTypecaster.new.call(biglearn_api_secrets[:stub])
  config.fake_store = ActiveSupport::Cache::RedisStore.new(
    url: redis_secrets[:url],
    namespace: redis_secrets[:namespaces][:fake_biglearn]
  )
end

biglearn_scheduler_secrets = biglearn_secrets[:scheduler]
OpenStax::Biglearn::Scheduler.configure do |config|
  config.server_url = biglearn_scheduler_secrets[:url]
  config.token = biglearn_scheduler_secrets[:token]
  config.client_id = biglearn_scheduler_secrets[:client_id]
  config.secret = biglearn_scheduler_secrets[:secret]
  config.stub = ActiveAttr::Typecasting::BooleanTypecaster.new.call(
    biglearn_scheduler_secrets[:stub]
  )
end

biglearn_sparfa_secrets = biglearn_secrets[:sparfa]
OpenStax::Biglearn::Sparfa.configure do |config|
  config.server_url = biglearn_sparfa_secrets[:url]
  config.token = biglearn_sparfa_secrets[:token]
  config.client_id = biglearn_sparfa_secrets[:client_id]
  config.secret = biglearn_sparfa_secrets[:secret]
  config.stub = ActiveAttr::Typecasting::BooleanTypecaster.new.call(biglearn_sparfa_secrets[:stub])
end
