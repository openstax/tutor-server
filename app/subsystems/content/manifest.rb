module Content
  class Manifest

    include Wrapper

    def self.from_yaml(yaml, strategy_class: ::Content::Strategies::Generated::Manifest)
      yaml = verify_and_return yaml, klass: String
      strategy = verify_and_return strategy_class.from_yaml(yaml), klass: strategy_class,
                                                                   error: StrategyError
      new(strategy: strategy)
    end

    def to_h
      verify_and_return @strategy.to_h, klass: Hash, error: StrategyError
    end

    def to_yaml
      verify_and_return @strategy.to_yaml, klass: String, error: StrategyError
    end

    def title
      verify_and_return @strategy.title, klass: String, error: StrategyError
    end

    def books
      verify_and_return @strategy.books, klass: ::Content::Manifest::Book, error: StrategyError
    end

    def valid?
      !!@strategy.valid?
    end

    def update_book!
      verify_and_return @strategy.update_book!, klass: self.class, error: StrategyError
    end

    def unlock_exercises!
      verify_and_return @strategy.unlock_exercises!, klass: self.class, error: StrategyError
    end

  end
end
