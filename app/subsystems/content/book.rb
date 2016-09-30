module Content
  class Book

    include Wrapper

    def id
      verify_and_return @strategy.id, klass: Integer, error: StrategyError
    end

    def tutor_uuid
      verify_and_return @strategy.tutor_uuid, klass: ::Content::Uuid, error: StrategyError
    end

    def url
      verify_and_return @strategy.url, klass: String, error: StrategyError
    end

    def archive_url
      verify_and_return @strategy.archive_url, klass: String, error: StrategyError
    end

    def webview_url
      verify_and_return @strategy.webview_url, klass: String, error: StrategyError
    end

    def uuid
      verify_and_return @strategy.uuid, klass: String, error: StrategyError
    end

    def short_id
      verify_and_return @strategy.short_id, klass: String, error: StrategyError, allow_nil: true
    end

    def version
      verify_and_return @strategy.version, klass: String, error: StrategyError
    end

    def cnx_id
      verify_and_return @strategy.cnx_id, klass: String, error: StrategyError
    end

    def title
      verify_and_return @strategy.title, klass: String, error: StrategyError
    end

    def ecosystem
      verify_and_return @strategy.ecosystem, klass: ::Content::Ecosystem, error: StrategyError
    end

    def chapters
      verify_and_return @strategy.chapters, klass: ::Content::Chapter, error: StrategyError
    end

    def pages
      verify_and_return @strategy.pages, klass: ::Content::Page, error: StrategyError
    end

    def exercises
      verify_and_return @strategy.exercises, klass: ::Content::Exercise, error: StrategyError
    end

  end
end
