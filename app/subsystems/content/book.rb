module Content
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

    def cnx_id
      verify_and_return @strategy.cnx_id, klass: String
    end

    def title
      verify_and_return @strategy.title, klass: String
    end

    def ecosystem
      verify_and_return @strategy.ecosystem, klass: ::Content::Ecosystem
    end

    def chapters
      verify_and_return @strategy.chapters, klass: ::Content::Chapter
    end

    def pages
      verify_and_return @strategy.pages, klass: ::Content::Page
    end

  end
end
