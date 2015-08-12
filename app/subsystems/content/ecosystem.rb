module Content
  class Ecosystem

    include Wrapper

    class << self
      def all(strategy_class: ::Content::Strategies::Direct::Ecosystem)
        verify_and_return strategy_class.all, klass: self
      end

      def create(title:, strategy_class: ::Content::Strategies::Direct::Ecosystem)
        verify_and_return strategy_class.create(title: title), klass: self
      end

      def create!(title:, strategy_class: ::Content::Strategies::Direct::Ecosystem)
        verify_and_return strategy_class.create!(title: title), klass: self
      end

      def find(*args, strategy_class: ::Content::Strategies::Direct::Ecosystem)
        verify_and_return strategy_class.find(*args), klass: self
      end

      def find_by_book_ids(*args, strategy_class: ::Content::Strategies::Direct::Ecosystem)
        verify_and_return strategy_class.find_by_book_ids(*args), klass: self, allow_nil: true
      end

      def find_by_chapter_ids(*args, strategy_class: ::Content::Strategies::Direct::Ecosystem)
        verify_and_return strategy_class.find_by_chapter_ids(*args), klass: self, allow_nil: true
      end

      def find_by_page_ids(*args, strategy_class: ::Content::Strategies::Direct::Ecosystem)
        verify_and_return strategy_class.find_by_page_ids(*args), klass: self, allow_nil: true
      end

      def find_by_exercise_ids(*args, strategy_class: ::Content::Strategies::Direct::Ecosystem)
        verify_and_return strategy_class.find_by_exercise_ids(*args), klass: self, allow_nil: true
      end
    end

    def id
      verify_and_return @strategy.id, klass: Integer
    end

    def books
      verify_and_return @strategy.books, klass: ::Content::Book
    end

    def books_by_ids(*ids)
      verify_and_return @strategy.books_by_ids(*ids), klass: ::Content::Book
    end

    def chapters
      verify_and_return @strategy.chapters, klass: ::Content::Chapter
    end

    def chapters_by_ids(*ids)
      verify_and_return @strategy.chapters_by_ids(*ids), klass: ::Content::Chapter
    end

    def pages
      verify_and_return @strategy.pages, klass: ::Content::Page
    end

    def pages_by_ids(*ids)
      verify_and_return @strategy.pages_by_ids(*ids), klass: ::Content::Page
    end

    def exercises
      verify_and_return @strategy.exercises, klass: ::Content::Exercise
    end

    def exercises_by_ids(*ids)
      verify_and_return @strategy.exercises_by_ids(*ids), klass: ::Content::Exercise
    end

    def exercises_by_numbers(*numbers)
      verify_and_return @strategy.exercises_by_numbers(*numbers), klass: ::Content::Exercise
    end

    def exercises_with_tags(*tags)
      verify_and_return @strategy.exercises_with_tags(*tags), klass: ::Content::Exercise
    end

    def pools
      verify_and_return @strategy.pools, klass: ::Content::Pool
    end

    def reading_dynamic_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Content::Page,
                                                             error: ArgumentError
      pools = @strategy.reading_dynamic_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Content::Pool
    end

    def reading_try_another_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Content::Page,
                                                             error: ArgumentError
      pools = @strategy.reading_try_another_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Content::Pool
    end

    def homework_core_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Content::Page,
                                                             error: ArgumentError
      pools = @strategy.homework_core_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Content::Pool
    end

    def homework_dynamic_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Content::Page,
                                                             error: ArgumentError
      pools = @strategy.homework_dynamic_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Content::Pool
    end

    def practice_widget_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Content::Page,
                                                             error: ArgumentError
      pools = @strategy.practice_widget_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Content::Pool
    end

    def title
      verify_and_return @strategy.title, klass: String
    end

  end
end
