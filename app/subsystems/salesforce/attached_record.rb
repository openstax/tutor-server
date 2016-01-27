module Salesforce
  class AttachedRecord

    include Wrapper

    self.strategy_class = ::Salesforce::Strategies::Direct::AttachedRecord

    def self.all
      verify_and_return strategy_class.all, klass: self, error: StrategyError
    end

    def self.preload
      verify_and_return strategy_class.preload, klass: self, error: StrategyError
    end

    def record
      @strategy.record
    end

    def attached_to
      @strategy.attached_to
    end

  end
end
