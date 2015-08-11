module Ecosystem
  class Exercise

    include Wrapper

    def id
      verify_and_return @strategy.id, klass: Integer
    end

    def url
      verify_and_return @strategy.url, klass: String
    end

    def uid
      verify_and_return @strategy.uid, klass: String
    end

    def number
      verify_and_return @strategy.number, klass: Integer
    end

    def version
      verify_and_return @strategy.version, klass: Integer
    end

    def title
      verify_and_return @strategy.title, klass: String, allow_nil: true
    end

    def content
      verify_and_return @strategy.content, klass: String
    end

    def tags
      verify_and_return @strategy.tags, klass: ::Ecosystem::Tag
    end

    def los
      verify_and_return @strategy.los, klass: ::Ecosystem::Tag
    end

    def aplos
      verify_and_return @strategy.aplos, klass: ::Ecosystem::Tag
    end

    def page
      verify_and_return @strategy.page, klass: ::Ecosystem::Page
    end

  end
end
