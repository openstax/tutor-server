module Ecosystem
  class Ecosystem

    include Wrapper

    def self.create(strategy_class: ::Ecosystem::Strategies::Direct::Ecosystem)
      new(strategy: strategy_class.create)
    end

    def self.create!(strategy_class: ::Ecosystem::Strategies::Direct::Ecosystem)
      new(strategy: strategy_class.create!)
    end

    def eager_load
      verify_and_return @strategy.eager_load, klass: self.class
    end

    def id
      verify_and_return @strategy.id, klass: Integer
    end

    def books
      verify_and_return @strategy.books, klass: ::Ecosystem::Book
    end

    def books_by_ids(*ids)
      verify_and_return @strategy.books_by_ids(*ids), klass: ::Ecosystem::Book
    end

    def chapters
      verify_and_return @strategy.chapters, klass: ::Ecosystem::Chapter
    end

    def chapters_by_ids(*ids)
      verify_and_return @strategy.chapters_by_ids(*ids), klass: ::Ecosystem::Chapter
    end

    def pages
      verify_and_return @strategy.pages, klass: ::Ecosystem::Page
    end

    def pages_by_ids(*ids)
      verify_and_return @strategy.pages_by_ids(*ids), klass: ::Ecosystem::Page
    end

    def exercises
      verify_and_return @strategy.exercises, klass: ::Ecosystem::Exercise
    end

    def exercises_by_ids(*ids)
      verify_and_return @strategy.exercises_by_ids(*ids), klass: ::Ecosystem::Exercise
    end

    def exercises_by_numbers(*numbers)
      verify_and_return @strategy.exercises_by_numbers(*numbers), klass: ::Ecosystem::Exercise
    end

    def exercises_with_tags(*tags)
      verify_and_return @strategy.exercises_with_tags(*tags), klass: ::Ecosystem::Exercise
    end

    def pools
      verify_and_return @strategy.pools, klass: ::Ecosystem::Pool
    end

    def reading_dynamic_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Ecosystem::Page
      pools = @strategy.reading_dynamic_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Ecosystem::Pool
    end

    def reading_try_another_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Ecosystem::Page
      pools = @strategy.reading_try_another_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Ecosystem::Pool
    end

    def homework_core_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Ecosystem::Page
      pools = @strategy.homework_core_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Ecosystem::Pool
    end

    def homework_dynamic_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Ecosystem::Page
      pools = @strategy.homework_dynamic_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Ecosystem::Pool
    end

    def practice_widget_pools(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Ecosystem::Page
      pools = @strategy.practice_widget_pools(pages: pages_arr)
      verify_and_return pools, klass: ::Ecosystem::Pool
    end

  end
end
