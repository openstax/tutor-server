module Content
  class Page

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

    def uuid
      verify_and_return @strategy.uuid, klass: ::Content::Uuid, error: StrategyError
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

    def content
      verify_and_return @strategy.content, klass: String, error: StrategyError
    end

    def chapter
      verify_and_return @strategy.chapter, klass: ::Content::Chapter, error: StrategyError
    end

    def reading_dynamic_pool
      verify_and_return @strategy.reading_dynamic_pool, klass: ::Content::Pool,
                                                        error: StrategyError
    end

    def reading_context_pool
      verify_and_return @strategy.reading_context_pool, klass: ::Content::Pool, error: StrategyError
    end

    def homework_core_pool
      verify_and_return @strategy.homework_core_pool, klass: ::Content::Pool, error: StrategyError
    end

    def homework_dynamic_pool
      verify_and_return @strategy.homework_dynamic_pool, klass: ::Content::Pool,
                                                         error: StrategyError
    end

    def practice_widget_pool
      verify_and_return @strategy.practice_widget_pool, klass: ::Content::Pool,
                                                        error: StrategyError
    end

    def concept_coach_pool
      verify_and_return @strategy.concept_coach_pool, klass: ::Content::Pool, error: StrategyError
    end

    def all_exercises_pool
      verify_and_return @strategy.all_exercises_pool, klass: ::Content::Pool, error: StrategyError
    end

    def exercises
      verify_and_return @strategy.exercises, klass: ::Content::Exercise, error: StrategyError
    end

    def book_location
      verify_and_return @strategy.book_location, klass: Integer, error: StrategyError
    end

    def is_intro?
      !!@strategy.is_intro?
    end

    def fragments
      @strategy.fragments
    end

    def tags
      verify_and_return @strategy.tags, klass: ::Content::Tag, error: StrategyError
    end

    def los
      verify_and_return @strategy.los, klass: ::Content::Tag, error: StrategyError
    end

    def aplos
      verify_and_return @strategy.aplos, klass: ::Content::Tag, error: StrategyError
    end

    def related_content(title: nil, book_location: nil)
      related_content = @strategy.related_content(title: title, book_location: book_location)
      verify_and_return related_content, klass: Hash, error: StrategyError
    end

    def snap_labs
      verify_and_return @strategy.snap_labs, klass: Hash, error: StrategyError
    end

    def snap_labs_with_page_id
      verify_and_return @strategy.snap_labs_with_page_id, klass: Hash, error: StrategyError
    end

    def to_model
      @strategy.to_model
    end

  end
end
