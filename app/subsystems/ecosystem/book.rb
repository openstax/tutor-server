module Ecosystem
  class Book

    include Wrapper

    def id
      verify_and_return @strategy.id, klass: Integer
    end

    def url
      verify_and_return @strategy.url, klass: String
    end

    def uuid
      verify_and_return @strategy.uuid, klass: String
    end

    def version
      verify_and_return @strategy.version, klass: String
    end

    def title
      verify_and_return @strategy.title, klass: String
    end

    def chapters
      verify_and_return @strategy.chapters, klass: ::Ecosystem::Chapter
    end

    def pages
      verify_and_return @strategy.pages, klass: ::Ecosystem::Page
    end

    def toc
      verify_and_return @strategy.toc, klass: Hash
    end

  end
end
