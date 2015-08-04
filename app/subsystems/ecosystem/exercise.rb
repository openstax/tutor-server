module Ecosystem
  class Exercise

    include Wrapper

    def id
      verify_and_return @strategy.id, klass: Integer
    end

    def uid
      verify_and_return @strategy.uid, klass: String
    end

    def url
      verify_and_return @strategy.url, klass: String
    end

    def title
      verify_and_return @strategy.title, klass: String, allow_nil: true
    end

    def content
      verify_and_return @strategy.content, klass: String
    end

    def tags
      verify_and_return @strategy.tags, klass: String
    end

    def los
      verify_and_return @strategy.los, klass: String
    end

    def aplos
      verify_and_return @strategy.aplos, klass: String
    end

    def pages
      verify_and_return @strategy.pages, klass: ::Ecosystem::Page
    end

    def related_content
      verify_and_return @strategy.related_content, klass: Hash
    end

  end
end
