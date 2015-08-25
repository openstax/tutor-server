module Content
  class Chapter

    include Wrapper

    def id
      verify_and_return @strategy.id, klass: Integer, error: ::Content::StrategyError
    end

    def title
      verify_and_return @strategy.title, klass: String, error: ::Content::StrategyError
    end

    def book
      verify_and_return @strategy.book, klass: ::Content::Book, error: ::Content::StrategyError
    end

    def pages
      verify_and_return @strategy.pages, klass: ::Content::Page, error: ::Content::StrategyError
    end

    def book_location
      verify_and_return @strategy.book_location, klass: Integer, error: ::Content::StrategyError
    end

  end
end
