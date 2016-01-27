module Salesforce
  class AttachedRecord

    include Wrapper

    self.strategy_class = ::Salesforce::Strategies::Direct::AttachedRecord

    def self.all
      verify_and_return strategy_class.all, klass: self, error: StrategyError
    end

    def self.preload(what = :all)
      verify_and_return strategy_class.preload(what), klass: self, error: StrategyError
    end

    def record
      @strategy.record
    end

    def attached_to
      @strategy.attached_to
    end

  end
end
