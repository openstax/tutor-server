exercises_secrets = Rails.application.secrets.openstax[:exercises] || { 'stub' => true } #

OpenStax::Exercises::V1.configure do |config|
  config.server_url = exercises_secrets[:url]
  config.client_id  = exercises_secrets[:client_id]
  config.secret     = exercises_secrets[:secret]
  config.stub       = ActiveAttr::Typecasting::BooleanTypecaster.new.call(exercises_secrets[:stub])
  redis_secrets     = Rails.application.secrets.redis
  config.fake_store = ActiveSupport::Cache::RedisStore.new(
    url: redis_secrets[:url],
    namespace: redis_secrets[:namespaces][:fake_exercises]
  )
end
