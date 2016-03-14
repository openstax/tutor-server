module Settings
  module Timecop

    class << self

      def offset
        Settings::Redis.store.get('timecop:offset')
      end

      def offset=(value)
        Settings::Redis.store.set('timecop:offset', value)
      end

    end

  end
end
