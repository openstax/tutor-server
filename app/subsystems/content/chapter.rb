module Content
  class Chapter

    include Wrapper

    def id
      verify_and_return @strategy.id, klass: Integer
    end

    def title
      verify_and_return @strategy.title, klass: String
    end

    def book
      verify_and_return @strategy.book, klass: ::Content::Book
    end

    def pages
      verify_and_return @strategy.pages, klass: ::Content::Page
    end

    def book_location
      verify_and_return @strategy.book_location, klass: Integer
    end

  end
end
