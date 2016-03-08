module Settings
  module Notifications
    KEY = 'system:notifications'
    class << self
      include Enumerable

      # Returns a string that contains unparsed JSON which is
      # intended to be sent directly to the user without parsing.
      def raw
        Settings.store.get(KEY) || '[]'
      end

      # Parsed JSON content of messages.
      # yields objects with 'id' and 'message' keys
      def each
        messages.each{|notice| yield notice }
      end

      def add(message)
        message = {'id' => SecureRandom.uuid, 'message' => message}
        update!( messages.push(message) )
        message
      end

      def remove(message_id)
        update!(
          messages.reject{|message| message['id'] == message_id }
        )
      end

      private

      def messages
        ActiveSupport::JSON.decode(raw)
      end

      def update!(json)
        Settings.store.set(KEY, ActiveSupport::JSON.encode(json))
      end

    end
  end
end
