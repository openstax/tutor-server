module Content
  class Ecosystem

    include Wrapper

    class << self
      def all(strategy_class: ::Content::Strategies::Direct::Ecosystem)
        verify_and_return strategy_class.all, klass: self, error: StrategyError
      end

      def create(title:, comments: nil, strategy_class: ::Content::Strategies::Direct::Ecosystem)
        title = verify_and_return title, klass: String
        comments = verify_and_return comments, allow_nil: true, allow_blank: true, klass: String
        verify_and_return strategy_class.create(title: title, comments: comments),
                          klass: self, error: StrategyError
      end

      def create!(title:, comments: nil, strategy_class: ::Content::Strategies::Direct::Ecosystem)
        title = verify_and_return title, klass: String
        comments = verify_and_return comments, allow_nil: true, allow_blank: true, klass: String
        verify_and_return strategy_class.create!(title: title, comments: comments),
                          klass: self, error: StrategyError
      end

      def find(*args, strategy_class: ::Content::Strategies::Direct::Ecosystem)
        verify_and_return strategy_class.find(*args), klass: self, error: StrategyError
      end

      def find_by_book_ids(*args, strategy_class: ::Content::Strategies::Direct::Ecosystem)
        verify_and_return strategy_class.find_by_book_ids(*args),
                          klass: self, allow_nil: true, error: StrategyError
      end

      def find_by_chapter_ids(*args, strategy_class: ::Content::Strategies::Direct::Ecosystem)
        verify_and_return strategy_class.find_by_chapter_ids(*args),
                          klass: self, allow_nil: true, error: StrategyError
      end

      def find_by_page_ids(*args, strategy_class: ::Content::Strategies::Direct::Ecosystem)
        verify_and_return strategy_class.find_by_page_ids(*args),
                          klass: self, allow_nil: true, error: StrategyError
      end

      def find_by_exercise_ids(*args, strategy_class: ::Content::Strategies::Direct::Ecosystem)
        verify_and_return strategy_class.find_by_exercise_ids(*args),
                          klass: self, allow_nil: true, error: StrategyError
      end
    end

    def id
      verify_and_return @strategy.id, klass: Integer, error: StrategyError
    end

    def manifest
      verify_and_return @strategy.manifest, klass: ::Content::Manifest, error: StrategyError
    end

    def books
      verify_and_return @strategy.books, klass: ::Content::Book, error: StrategyError
    end

    def books_by_ids(*ids)
      verify_and_return @strategy.books_by_ids(*ids),
                        klass: ::Content::Book, error: StrategyError
    end

    def chapters
      verify_and_return @strategy.chapters,
                        klass: ::Content::Chapter, error: StrategyError
    end

    def chapters_by_ids(*ids)
      verify_and_return @strategy.chapters_by_ids(*ids),
                        klass: ::Content::Chapter, error: StrategyError
    end

    def pages
      verify_and_return @strategy.pages, klass: ::Content::Page, error: StrategyError
    end

    def pages_by_ids(*ids)
      verify_and_return @strategy.pages_by_ids(*ids),
                        klass: ::Content::Page, error: StrategyError
    end

    def exercises
      verify_and_return @strategy.exercises,
                        klass: ::Content::Exercise, error: StrategyError
    end

    def exercises_by_ids(*ids)
      verify_and_return @strategy.exercises_by_ids(*ids),
                        klass: ::Content::Exercise, error: StrategyError
    end

    def exercises_by_numbers(*numbers)
      verify_and_return @strategy.exercises_by_numbers(*numbers),
                        klass: ::Content::Exercise, error: StrategyError
    end

    def exercises_with_tags(*tags)
      verify_and_return @strategy.exercises_with_tags(*tags),
                        klass: ::Content::Exercise, error: StrategyError
    end

    def pools
      verify_and_return @strategy.pools, klass: ::Content::Pool, error: StrategyError
    end

    def reading_dynamic_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Content::Page
      pools = @strategy.reading_dynamic_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Content::Pool, error: StrategyError
    end

    def reading_context_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Content::Page
      pools = @strategy.reading_context_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Content::Pool, error: StrategyError
    end

    def homework_core_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Content::Page
      pools = @strategy.homework_core_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Content::Pool, error: StrategyError
    end

    def homework_dynamic_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Content::Page
      pools = @strategy.homework_dynamic_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Content::Pool, error: StrategyError
    end

    def practice_widget_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Content::Page
      pools = @strategy.practice_widget_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Content::Pool, error: StrategyError
    end

    def concept_coach_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Content::Page
      pools = @strategy.concept_coach_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Content::Pool, error: StrategyError
    end

    def all_exercises_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Content::Page
      pools = @strategy.all_exercises_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Content::Pool, error: StrategyError
    end

    def tags
      verify_and_return @strategy.tags, klass: ::Content::Tag, error: StrategyError
    end

    def tags_by_values(*values)
      verify_and_return @strategy.tags_by_values(*values),
                        klass: ::Content::Tag, error: StrategyError
    end

    def title
      verify_and_return @strategy.title, klass: String, error: StrategyError
    end

    def comments
      verify_and_return @strategy.comments, klass: String,
                                            allow_blank: true,
                                            allow_nil: true,
                                            error: StrategyError
    end

    def imported_at
      verify_and_return @strategy.imported_at,
                        klass: ActiveSupport::TimeWithZone, error: StrategyError
    end

    def deletable?
      @strategy.deletable?
    end

    def to_model
      @strategy.to_model
    end

  end
end
