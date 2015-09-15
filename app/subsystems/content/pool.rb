module Content
  class Pool

    include Wrapper

    def uuid
      verify_and_return @strategy.uuid, klass: ::Content::Uuid,
                                        allow_nil: true,
                                        error: StrategyError
    end

    def pool_type
      verify_and_return @strategy.pool_type, klass: Symbol, error: StrategyError
    end

    def pool_types
      verify_and_return @strategy.pool_types, klass: Symbol, error: ::Content::StrategyError
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
