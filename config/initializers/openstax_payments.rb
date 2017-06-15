payments_secrets = Rails.application.secrets['openstax']['payments']
redis_secrets = Rails.application.secrets['redis']

OpenStax::Payments::Api.configure do |config|
  config.server_url = payments_secrets['url']
  config.client_id  = payments_secrets['client_id']
  config.secret     = payments_secrets['secret']
  config.stub       = !!payments_secrets['stub']
  config.fake_store = ActiveSupport::Cache::RedisStore.new(
    url: redis_secrets['url'],
    namespace: redis_secrets['namespaces']['fake_payments']
  )
end
