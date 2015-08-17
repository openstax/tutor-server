module VerifiedCollections
  def self.included(base)
    base.extend ClassMethods
  end

  # Convenience instance method that calls the verify_and_return class method
  def verify_and_return(object, klass:, error: TypeError,
                        allow_blank: false, allow_nil: false)
    self.class.verify_and_return(object, klass: klass, error: error,
                                 allow_blank: allow_blank, allow_nil: allow_nil)
  end

  module ClassMethods
    def verify_and_return(object, klass:, error: TypeError,
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
