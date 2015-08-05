module Ecosystem
  class Chapter

    include Wrapper

    def title
      verify_and_return @strategy.title, klass: String
    end

    def pages
      verify_and_return @strategy.pages, klass: ::Ecosystem::Page
    end

    def book_location
      verify_and_return @strategy.book_location, klass: Integer
    end

  end
end
