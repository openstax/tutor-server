module OpenStax
  module Payments

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

    class RemoteError < StandardError
      attr_reader :original, :status

      def initialize(msg: nil, status: nil, original:$!)
        super(msg)
        @original = original
        @status = status || original.try(:response).try(:status)
        set_backtrace(original.backtrace)
      end

      def inspect
        [super, @status.inspect, @original.inspect].join(" ")
      end

      def message
        [ super,
          "#{@status || 'status-less'} error response from Payments",
          "(#{@original.message})"
        ].join(" ")
      end
    end

  end
end
