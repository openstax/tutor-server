module Ecosystem
  module Wrapper

    def self.included(base)
      base.extend ClassMethods
    end

    def initialize(strategy:)
      @strategy = strategy
    end

    # Returns the strategy
    # For internal use only
    def _strategy
      @strategy
    end

    # Wrappers are equal if the strategies are equal
    def ==(other)
      self.class == other.class && _strategy == other._strategy
    end

    def eql?(other)
      self.class.eql?(other.class) && _strategy.eql?(other._strategy)
    end

    protected

    # Convenience instance method that calls the verify_and_return class method
    def verify_and_return(object, klass:, error: ::Ecosystem::StrategyError,
                          allow_blank: false, allow_nil: false)
      self.class.verify_and_return(object, klass: klass, error: error,
                                   allow_blank: allow_blank, allow_nil: allow_nil)
    end

    module ClassMethods
      # Verifies that the given "object" is of the given "klass"
      # Returns the object or raises the given "error"
      def verify_and_return(object, klass:, error: ::Ecosystem::StrategyError,
                                 allow_blank: false, allow_nil: false)
        return object if klass == Array && object.is_a?(Array)

        if allow_blank
          return object if object.blank?
        elsif allow_nil
          return object if object.nil?
        end

        [object].flatten.each do |obj|
          raise(error,
                "Tested argument was of class '#{obj.class}' instead of the expected '#{klass}'.",
                caller) unless obj.is_a? klass
        end

        object
      end
    end

  end
end
