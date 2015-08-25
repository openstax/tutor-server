module Content
  class Page

    include Wrapper

    def id
      verify_and_return @strategy.id, klass: Integer, error: ::Content::StrategyError
    end

    def url
      verify_and_return @strategy.url, klass: String, error: ::Content::StrategyError
    end

    def uuid
      verify_and_return @strategy.uuid, klass: String, error: ::Content::StrategyError
    end

    def version
      verify_and_return @strategy.version, klass: String, error: ::Content::StrategyError
    end

    def cnx_id
      verify_and_return @strategy.cnx_id, klass: String, error: ::Content::StrategyError
    end

    def title
      verify_and_return @strategy.title, klass: String, error: ::Content::StrategyError
    end

    def content
      verify_and_return @strategy.content, klass: String, error: ::Content::StrategyError
    end

    def chapter
      verify_and_return @strategy.chapter, klass: ::Content::Chapter,
                                           error: ::Content::StrategyError
    end

    def reading_dynamic_pool
      verify_and_return @strategy.reading_dynamic_pool, klass: ::Content::Pool,
                                                        error: ::Content::StrategyError
    end

    def reading_try_another_pool
      verify_and_return @strategy.reading_try_another_pool, klass: ::Content::Pool,
                                                            error: ::Content::StrategyError
    end

    def homework_core_pool
      verify_and_return @strategy.homework_core_pool, klass: ::Content::Pool,
                                                      error: ::Content::StrategyError
    end

    def homework_dynamic_pool
      verify_and_return @strategy.homework_dynamic_pool, klass: ::Content::Pool,
                                                         error: ::Content::StrategyError
    end

    def practice_widget_pool
      verify_and_return @strategy.practice_widget_pool, klass: ::Content::Pool,
                                                        error: ::Content::StrategyError
    end

    def exercises
      verify_and_return @strategy.exercises, klass: ::Content::Exercise,
                                             error: ::Content::StrategyError
    end

    def book_location
      verify_and_return @strategy.book_location, klass: Integer, error: ::Content::StrategyError
    end

    def is_intro?
      !!@strategy.is_intro?
    end

    def fragments
      @strategy.fragments
    end

    def tags
      verify_and_return @strategy.tags, klass: ::Content::Tag, error: ::Content::StrategyError
    end

    def los
      verify_and_return @strategy.los, klass: ::Content::Tag, error: ::Content::StrategyError
    end

    def aplos
      verify_and_return @strategy.aplos, klass: ::Content::Tag, error: ::Content::StrategyError
    end

    def related_content(title: nil, book_location: nil)
      related_content = @strategy.related_content(title: title, book_location: book_location)
      verify_and_return related_content, klass: Hash, error: ::Content::StrategyError
    end

  end
end
