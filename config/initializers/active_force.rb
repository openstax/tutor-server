module ActiveForce

  mattr_accessor :cache_store
  secrets = Rails.application.secrets[:redis]
  self.cache_store = Redis::Store.new(
    url: secrets[:url],
    namespace: secrets[:namespaces][:active_force],
    expires_in: 1.year
  )

end
