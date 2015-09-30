module Content
  class Exercise

    include Wrapper

    def id
      verify_and_return @strategy.id, klass: Integer, error: StrategyError
    end

    def url
      verify_and_return @strategy.url, klass: String, error: StrategyError
    end

    def uid
      verify_and_return @strategy.uid, klass: String, error: StrategyError
    end

    def number
      verify_and_return @strategy.number, klass: Integer, error: StrategyError
    end

    def version
      verify_and_return @strategy.version, klass: Integer, error: StrategyError
    end

    def title
      verify_and_return @strategy.title, klass: String, allow_nil: true, error: StrategyError
    end

    def content
      verify_and_return @strategy.content, klass: String, error: StrategyError
    end

    def tags
      verify_and_return @strategy.tags, klass: ::Content::Tag, error: StrategyError
    end

    def los
      verify_and_return @strategy.los, klass: ::Content::Tag, error: StrategyError
    end

    def aplos
      verify_and_return @strategy.aplos, klass: ::Content::Tag, error: StrategyError
    end

    def page
      verify_and_return @strategy.page, klass: ::Content::Page, error: StrategyError
    end

  end
end
