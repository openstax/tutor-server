module Content
  class Book

    include Wrapper

    def id
      verify_and_return @strategy.id, klass: Integer, error: ::Content::StrategyError
    end

    def url
      verify_and_return @strategy.url, klass: String, error: ::Content::StrategyError
    end

    def uuid
      verify_and_return @strategy.uuid, klass: String, error: ::Content::StrategyError
    end

    def version
      verify_and_return @strategy.version, klass: String, error: ::Content::StrategyError
    end

    def cnx_id
      verify_and_return @strategy.cnx_id, klass: String, error: ::Content::StrategyError
    end

    def title
      verify_and_return @strategy.title, klass: String, error: ::Content::StrategyError
    end

    def ecosystem
      verify_and_return @strategy.ecosystem,
                        klass: ::Content::Ecosystem, error: ::Content::StrategyError
    end

    def chapters
      verify_and_return @strategy.chapters,
                        klass: ::Content::Chapter, error: ::Content::StrategyError
    end

    def pages
      verify_and_return @strategy.pages, klass: ::Content::Page, error: ::Content::StrategyError
    end

  end
end
