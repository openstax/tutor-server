module OpenStax
  module Configurable
    class ClientError < StandardError
      def initialize(msg, original=$!)
        super(msg)
        @original = original
        set_backtrace(original.backtrace)
      end

      def inspect
        [super, @original.inspect].join(" ")
      end

      def message
        [super, "(#{@original.message})"].join(" ")
      end
    end
  end
end
