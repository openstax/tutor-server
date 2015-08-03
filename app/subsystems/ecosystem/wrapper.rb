module Ecosystem
  class Wrapper

    def initialize(strategy:)
      @strategy = strategy
    end

    protected

    def raise_collection_class_error(collection:, klass:, error:)
      raise error if [collection].flatten.compact.detect{|obj| !obj.is_a? klass}
    end

  end
end
