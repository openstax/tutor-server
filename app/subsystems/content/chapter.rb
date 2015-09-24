module Content
  class Chapter

    include Wrapper

    def id
      verify_and_return @strategy.id, klass: Integer, error: StrategyError
    end

    def title
      verify_and_return @strategy.title, klass: String, error: StrategyError
    end

    def book
      verify_and_return @strategy.book, klass: ::Content::Book, error: StrategyError
    end

    def pages
      verify_and_return @strategy.pages, klass: ::Content::Page, error: StrategyError
    end

    def all_exercises_pool
      verify_and_return @strategy.all_exercises_pool, klass: ::Content::Pool, error: StrategyError
    end

    def book_location
      verify_and_return @strategy.book_location, klass: Integer, error: StrategyError
    end

  end
end
