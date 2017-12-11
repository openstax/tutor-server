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

    def salesforce_object
      @strategy.salesforce_object
    end

    def salesforce_id
      @strategy.salesforce_id
    end

    def attached_to
      @strategy.attached_to
    end

    def attached_to_class_name
      @strategy.attached_to_class_name
    end

    def attached_to_id
      @strategy.attached_to_id
    end

    def destroy!
      @strategy.destroy!
    end

    def deleted?
      @strategy.deleted?
    end

  end
end
