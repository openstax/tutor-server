module Content
  class Ecosystem

    include ModifiedWrapper

    use_strategy ::Content::Strategies::Direct::Ecosystem,
                 instance_methods: { id: Integer,
                                     pools: Pool,
                                     manifest: Manifest,
                                     books: Book,
                                     chapters: Chapter,
                                     pages: Page,
                                     tags: Tag,
                                     title: String,
									 comments: String,
                                     imported_at: ActiveSupport::TimeWithZone,
                                     exercises: Exercise }

    class << self
      def all
        verify_and_return strategy_class.all, klass: self, error: StrategyError
      end

      def create(title:, comments: nil)
        title = verify_and_return title, klass: String
        comments = verify_and_return comments, allow_nil: true, allow_blank: true, klass: String
        verify_and_return strategy_class.create(title: title, comments: comments),
                          klass: self, error: StrategyError
      end

      def create!(title:, comments: nil)
        title = verify_and_return title, klass: String
        comments = verify_and_return comments, allow_nil: true, allow_blank: true, klass: String
        verify_and_return strategy_class.create!(title: title, comments: comments),
                          klass: self, error: StrategyError
      end

      def find(*args)
        verify_and_return strategy_class.find(*args), klass: self, error: StrategyError
      end

      def find_by_book_ids(*args)
        verify_and_return strategy_class.find_by_book_ids(*args),
                          klass: self, allow_nil: true, error: StrategyError
      end

      def find_by_chapter_ids(*args)
        verify_and_return strategy_class.find_by_chapter_ids(*args),
                          klass: self, allow_nil: true, error: StrategyError
      end

      def find_by_page_ids(*args)
        verify_and_return strategy_class.find_by_page_ids(*args),
                          klass: self, allow_nil: true, error: StrategyError
      end

      def find_by_exercise_ids(*args)
        verify_and_return strategy_class.find_by_exercise_ids(*args),
                          klass: self, allow_nil: true, error: StrategyError
      end
    end

    def books_by_ids(*ids)
      verify_and_return strategy.books_by_ids(*ids),
                        klass: ::Content::Book, error: StrategyError
    end

    def chapters_by_ids(*ids)
      verify_and_return strategy.chapters_by_ids(*ids),
                        klass: ::Content::Chapter, error: StrategyError
    end

    def pages_by_ids(*ids)
      verify_and_return strategy.pages_by_ids(*ids),
                        klass: ::Content::Page, error: StrategyError
    end

    def exercises_by_ids(*ids)
      verify_and_return strategy.exercises_by_ids(*ids),
                        klass: ::Content::Exercise, error: StrategyError
    end

    def exercises_by_numbers(*numbers)
      verify_and_return strategy.exercises_by_numbers(*numbers),
                        klass: ::Content::Exercise, error: StrategyError
    end

    def exercises_with_tags(*tags)
      verify_and_return strategy.exercises_with_tags(*tags),
                        klass: ::Content::Exercise, error: StrategyError
    end

    def reading_dynamic_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Content::Page
      pools = strategy.reading_dynamic_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Content::Pool, error: StrategyError
    end

    def reading_try_another_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Content::Page
      pools = strategy.reading_try_another_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Content::Pool, error: StrategyError
    end

    def homework_core_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Content::Page
      pools = strategy.homework_core_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Content::Pool, error: StrategyError
    end

    def homework_dynamic_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Content::Page
      pools = strategy.homework_dynamic_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Content::Pool, error: StrategyError
    end

    def practice_widget_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Content::Page
      pools = strategy.practice_widget_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Content::Pool, error: StrategyError
    end

    def all_exercises_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Content::Page
      pools = strategy.all_exercises_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Content::Pool, error: StrategyError
    end

    def tags_by_values(*values)
      verify_and_return strategy.tags_by_values(*values),
                        klass: ::Content::Tag, error: StrategyError
    end

  end
end
