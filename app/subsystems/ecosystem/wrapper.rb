module Ecosystem
  module Wrapper

    def initialize(strategy:)
      @strategy = strategy
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

      [object].flatten.each do |obj|
        raise(
          error, "Tested argument was of class '#{obj.class}' instead of the expected '#{klass}'."
        ) unless obj.is_a? klass
      end

      object
    end

  end
end
