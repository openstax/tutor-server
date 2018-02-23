module Settings
  module Notifications

    KEY_BASE = 'notifications'

    VALID_TYPES = ['general', 'instructor']

    class << self
      def valid_type?(type:)
        VALID_TYPES.include? type.to_s
      end

      def add(type:, message:, from:, to:)
        key = key(type: type)

        json = { message: message, from: from, to: to }.to_json

        SecureRandom.uuid.tap do |uuid|
          Settings::Redis.store.hset(key, uuid, json)

          RequestStore.store.delete(key)
        end
      end

      def remove(type:, id:)
        key = key(type: type)

        json = Settings::Redis.store.hget(key, id)

        Settings::Redis.store.hdel(key, id)

        RequestStore.store.delete(key)

        JSON.parse(json)['message']
      end

      # Messages hashes, cached per request
      # Expired hashes are automatically deleted
      def all(type:, current_time: Time.current)
        key = key(type: type)

        RequestStore.store[key] ||= Settings::Redis.store.hgetall(key).map do |uuid, json|
          hash = JSON.parse json

          to = DateTime.parse(hash['to']) rescue nil
          if !to.nil? && current_time > to
            Settings::Redis.store.hdel(key, uuid)

            next
          end
          from = DateTime.parse(hash['from']) rescue nil

          OpenStruct.new id: uuid, type: type, message: hash['message'], from: from, to: to
        end.compact
      end

      # Active message hashes
      # Expired messages have already been deleted by the `all` method,
      # so we only need to check the `from` field
      def active(type:, current_time: Time.current)
        all(type: type, current_time: current_time).select do |notification|
          notification.from.nil? || current_time >= notification.from
        end
      end

      protected

      def key(type:)
        "#{KEY_BASE}/#{type}"
      end
    end

  end
end
