module Settings
  module Notifications

    KEY_BASE = 'notifications'

    VALID_TYPES = ['general', 'instructor']

    class << self
      def valid_type?(type)
        VALID_TYPES.include? type.to_s
      end

      def add(type, message)
        key = key(type)

        RequestStore.store[key] = nil

        SecureRandom.uuid.tap{ |uuid| Settings::Redis.store.hset(key, uuid, message) }
      end

      def remove(type, uuid)
        key = key(type)

        RequestStore.store[key] = nil

        Settings::Redis.store.hget(key, uuid).tap{ |message| Settings::Redis.store.hdel(key, uuid) }
      end

      # Messages hash, cached on a per-request basis
      def messages(type)
        key = key(type)

        RequestStore.store[key] ||= Settings::Redis.store.hgetall(key)
      end

      protected

      def key(type)
        "#{KEY_BASE}/#{type}"
      end
    end

  end
end
