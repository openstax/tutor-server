module Ecosystem
  module Wrapper

    def self.included(base)
      base.class_exec do
        def initialize(strategy:)
          @strategy = strategy
        end
      end
    end

    protected

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

      raise error if [object].flatten.any?{ |obj| !obj.is_a? klass }

      object
    end

  end
end
