module Ecosystem
  class Chapter

    include Wrapper

    def title
      verify_and_return @strategy.title, klass: String
    end

    def pages
      verify_and_return @strategy.pages, klass: ::Ecosystem::Page
    end

    def chapter_section
      verify_and_return @strategy.chapter_section, klass: Integer
    end

  end
end
