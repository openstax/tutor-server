module Content
  class Ecosystem

    include Wrapper

    class << self
      def all(strategy_class: ::Content::Strategies::Direct::Ecosystem)
        verify_and_return strategy_class.all, klass: self, error: ::Content::StrategyError
      end

      def create(title:, strategy_class: ::Content::Strategies::Direct::Ecosystem)
        verify_and_return strategy_class.create(title: title),
                          klass: self, error: ::Content::StrategyError
      end

      def create!(title:, strategy_class: ::Content::Strategies::Direct::Ecosystem)
        verify_and_return strategy_class.create!(title: title),
                          klass: self, error: ::Content::StrategyError
      end

      def find(*args, strategy_class: ::Content::Strategies::Direct::Ecosystem)
        verify_and_return strategy_class.find(*args),
                          klass: self, error: ::Content::StrategyError
      end

      def find_by_book_ids(*args, strategy_class: ::Content::Strategies::Direct::Ecosystem)
        verify_and_return strategy_class.find_by_book_ids(*args),
                          klass: self, allow_nil: true, error: ::Content::StrategyError
      end

      def find_by_chapter_ids(*args, strategy_class: ::Content::Strategies::Direct::Ecosystem)
        verify_and_return strategy_class.find_by_chapter_ids(*args),
                          klass: self, allow_nil: true, error: ::Content::StrategyError
      end

      def find_by_page_ids(*args, strategy_class: ::Content::Strategies::Direct::Ecosystem)
        verify_and_return strategy_class.find_by_page_ids(*args),
                          klass: self, allow_nil: true, error: ::Content::StrategyError
      end

      def find_by_exercise_ids(*args, strategy_class: ::Content::Strategies::Direct::Ecosystem)
        verify_and_return strategy_class.find_by_exercise_ids(*args),
                          klass: self, allow_nil: true, error: ::Content::StrategyError
      end
    end

    def id
      verify_and_return @strategy.id, klass: Integer, error: ::Content::StrategyError
    end

    def books
      verify_and_return @strategy.books, klass: ::Content::Book, error: ::Content::StrategyError
    end

    def books_by_ids(*ids)
      verify_and_return @strategy.books_by_ids(*ids),
                        klass: ::Content::Book, error: ::Content::StrategyError
    end

    def chapters
      verify_and_return @strategy.chapters,
                        klass: ::Content::Chapter, error: ::Content::StrategyError
    end

    def chapters_by_ids(*ids)
      verify_and_return @strategy.chapters_by_ids(*ids),
                        klass: ::Content::Chapter, error: ::Content::StrategyError
    end

    def pages
      verify_and_return @strategy.pages, klass: ::Content::Page, error: ::Content::StrategyError
    end

    def pages_by_ids(*ids)
      verify_and_return @strategy.pages_by_ids(*ids),
                        klass: ::Content::Page, error: ::Content::StrategyError
    end

    def exercises
      verify_and_return @strategy.exercises,
                        klass: ::Content::Exercise, error: ::Content::StrategyError
    end

    def exercises_by_ids(*ids)
      verify_and_return @strategy.exercises_by_ids(*ids),
                        klass: ::Content::Exercise, error: ::Content::StrategyError
    end

    def exercises_by_numbers(*numbers)
      verify_and_return @strategy.exercises_by_numbers(*numbers),
                        klass: ::Content::Exercise, error: ::Content::StrategyError
    end

    def exercises_with_tags(*tags)
      verify_and_return @strategy.exercises_with_tags(*tags),
                        klass: ::Content::Exercise, error: ::Content::StrategyError
    end

    def pools
      verify_and_return @strategy.pools, klass: ::Content::Pool, error: ::Content::StrategyError
    end

    def reading_dynamic_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Content::Page
      pools = @strategy.reading_dynamic_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Content::Pool, error: ::Content::StrategyError
    end

    def reading_try_another_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Content::Page
      pools = @strategy.reading_try_another_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Content::Pool, error: ::Content::StrategyError
    end

    def homework_core_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Content::Page
      pools = @strategy.homework_core_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Content::Pool, error: ::Content::StrategyError
    end

    def homework_dynamic_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Content::Page
      pools = @strategy.homework_dynamic_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Content::Pool, error: ::Content::StrategyError
    end

    def practice_widget_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Content::Page
      pools = @strategy.practice_widget_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Content::Pool, error: ::Content::StrategyError
    end

    def tags
      verify_and_return @strategy.tags, klass: ::Content::Tag, error: ::Content::StrategyError
    end

    def tags_by_values(*values)
      verify_and_return @strategy.tags_by_values(*values),
                        klass: ::Content::Tag, error: ::Content::StrategyError
    end

    def title
      verify_and_return @strategy.title, klass: String, error: ::Content::StrategyError
    end

    def imported_at
      verify_and_return @strategy.imported_at,
                        klass: ActiveSupport::TimeWithZone, error: ::Content::StrategyError
    end

  end
end
