module Settings
  class Redis
    redis_secrets = Rails.application.secrets.redis
    @store = ::Redis::Store.new(
      url: redis_secrets[:url],
      namespace: redis_secrets[:namespaces][:settings]
    )

    class << self
      extend Forwardable

      def_delegators :@store, :get, :set, :hget, :hset, :hdel, :hgetall
    end
  end
end
