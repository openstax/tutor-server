module Content
  class Manifest

    include Wrapper

    def self.from_yaml(yaml, strategy_class: Content::Strategies::Generated::Manifest)
      yaml = verify_and_return yaml, klass: String
      strategy = verify_and_return strategy_class.from_yaml(yaml), klass: strategy_class,
                                                                   error: StrategyError
      new(strategy: strategy)
    end

    def to_yaml
      verify_and_return @strategy.to_yaml, klass: String, error: StrategyError
    end

    def ecosystem_title
      verify_and_return @strategy.ecosystem_title, klass: String, error: StrategyError
    end

    def archive_url
      verify_and_return @strategy.archive_url, klass: String, error: StrategyError, allow_nil: true
    end

    def book_ids
      verify_and_return @strategy.book_ids, klass: String, error: StrategyError
    end

    def exercise_ids
      verify_and_return @strategy.exercise_ids, klass: String, error: StrategyError, allow_nil: true
    end

    def valid?
      !!@strategy.valid?
    end

    def update_book!
      verify_and_return @strategy.update_book!, klass: @strategy.class, error: StrategyError
      self
    end

    def unlock_exercises!
      verify_and_return @strategy.unlock_exercises!, klass: @strategy.class, error: StrategyError
      self
    end

  end
end
