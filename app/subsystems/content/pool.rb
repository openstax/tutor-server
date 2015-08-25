module Content
  class Pool

    include Wrapper

    def uuid
      verify_and_return @strategy.uuid, klass: ::Content::Uuid,
                                        allow_nil: true,
                                        error: ::Content::StrategyError
    end

    def pool_type
      verify_and_return @strategy.pool_type, klass: Symbol, error: ::Content::StrategyError
    end

    def exercise_ids
      verify_and_return @strategy.exercise_ids, klass: Integer, error: ::Content::StrategyError
    end

    def exercises
      verify_and_return @strategy.exercises, klass: ::Content::Exercise,
                                             error: ::Content::StrategyError
    end

  end
end
