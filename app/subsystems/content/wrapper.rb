module Content
  module Wrapper

    def self.included(base)
      base.send(:include, VerifiedCollections)
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
      self.class == other.class && @strategy == other._strategy
    end

    # Hash key equality
    def eql?(other)
      self.class.eql?(other.class) && @strategy.eql?(other._strategy)
    end

    # Hash function
    def hash
      self.class.hash ^ @strategy.hash
    end

  end
end
