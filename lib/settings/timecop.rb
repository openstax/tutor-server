module Settings
  module Timecop

    class << self

      def offset
        Settings::Redis.get('timecop:offset')
      end

      def offset=(value)
        Settings::Redis.set('timecop:offset', value)
      end

    end

  end
end
