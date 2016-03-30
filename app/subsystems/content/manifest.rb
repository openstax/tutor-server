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
      verify_and_return @strategy.archive_url, klass: String, error: StrategyError
    end

    def book_uuids
      verify_and_return @strategy.book_uuids, klass: ::Content::Uuid, error: StrategyError
    end

    def book_versions
      verify_and_return @strategy.book_versions, klass: String, error: StrategyError
    end

    def book_cnx_ids
      verify_and_return @strategy.book_cnx_ids, klass: String, error: StrategyError
    end

    def exercise_numbers
      verify_and_return @strategy.exercise_numbers, klass: Integer, error: StrategyError
    end

    def exercise_versions
      verify_and_return @strategy.exercise_versions, klass: Integer, error: StrategyError
    end

    def exercise_uids
      verify_and_return @strategy.exercise_uids, klass: String, error: StrategyError
    end

  end
end
