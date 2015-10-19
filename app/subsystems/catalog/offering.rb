module Catalog
  class Offering

    include Wrapper

    def id
      verify_and_return @strategy.id, klass: Integer, error: StrategyError
    end

    def identifier
      verify_and_return @strategy.identifier, klass: Integer, error: StrategyError
    end

  end
end
