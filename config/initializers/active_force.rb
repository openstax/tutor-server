module ActiveForce

  mattr_accessor :cache_store
  redis_secrets = Rails.application.secrets.redis
  self.cache_store = Redis::Store.new(
    url: redis_secrets[:url],
    namespace: redis_secrets[:namespaces][:active_force],
    expires_in: 1.year
  )

end
