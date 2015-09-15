module Content
  class Pool

    include Wrapper

    def self.pool_types(strategy_class: ::Content::Strategies::Direct::Ecosystem)
      verify_and_return strategy_class.pool_types, klass: Symbol, error: ::Content::StrategyError
    end

    def uuid
      verify_and_return @strategy.uuid, klass: ::Content::Uuid,
                                        allow_nil: true,
                                        error: StrategyError
    end

    def pool_type
      verify_and_return @strategy.pool_type, klass: Symbol, error: StrategyError
    end

    def exercise_ids
      verify_and_return @strategy.exercise_ids, klass: Integer, error: StrategyError
    end

    def exercises(preload_tags: false)
      verify_and_return @strategy.exercises(preload_tags: preload_tags),
                        klass: ::Content::Exercise, error: StrategyError
    end

  end
end
