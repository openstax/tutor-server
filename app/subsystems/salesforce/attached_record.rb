module Salesforce
  class AttachedRecord

    include Wrapper

    self.strategy_class = ::Salesforce::Strategies::Direct::AttachedRecord

    def record
      @strategy.record
    end

    def attached_to
      @strategy.attached_to
    end

  end
end
