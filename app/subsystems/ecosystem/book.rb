module Ecosystem
  class Book

    include Wrapper

    def title
      verify_and_return @strategy.title, klass: String
    end

    def chapters
      verify_and_return @strategy.chapters, klass: ::Ecosystem::Chapter
    end

    def pages
      verify_and_return @strategy.pages, klass: ::Ecosystem::Page
    end

  end
end
