module Content
  class Manifest

    include Wrapper

    def self.from_yaml(yaml:)
      yaml = verify_and_return yaml, klass: String
      verify_and_return @strategy.from_yaml(yaml: yaml), klass: self, error: StrategyError
    end

    def to_yaml
      verify_and_return @strategy.to_yaml, klass: String, error: StrategyError
    end

    def ecosystem_title
      verify_and_return @strategy.ecosystem_title, klass: String, error: StrategyError
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
