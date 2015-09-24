module Content
  class Tag

    include Wrapper

    def id
      verify_and_return @strategy.id, klass: Integer, error: StrategyError
    end

    def value
      verify_and_return @strategy.value, klass: String, error: StrategyError
    end

    def tag_type
      verify_and_return @strategy.tag_type, klass: String, error: StrategyError
    end

    def name
      verify_and_return @strategy.name, klass: String, allow_nil: true, error: StrategyError
    end

    def description
      verify_and_return @strategy.description, klass: String, allow_nil: true, error: StrategyError
    end

    def book_location
      verify_and_return @strategy.book_location, klass: Array, error: StrategyError
    end

    def data
      verify_and_return @strategy.data, klass: String, allow_nil: true, error: StrategyError
    end

    def visible?
      !!@strategy.visible?
    end

    def to_s
      value
    end

    def teks_tags
      verify_and_return @strategy.teks_tags, klass: ::Content::Tag, error: StrategyError
    end

  end
end
