module Ecosystem
  class Ecosystem

    include Wrapper

    def self.create(*args, strategy_class: ::Ecosystem::Strategies::Direct::Ecosystem)
      new(strategy: strategy_class.create(*args))
    end

    def self.create!(*args, strategy_class: ::Ecosystem::Strategies::Direct::Ecosystem)
      new(strategy: strategy_class.create!(*args))
    end

    def id
      verify_and_return @strategy.id, klass: Integer
    end

    def books
      verify_and_return @strategy.books, klass: ::Ecosystem::Book
    end

    def exercises
      verify_and_return @strategy.exercises, klass: ::Ecosystem::Exercise
    end

    def reading_core_exercises(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Ecosystem::Page
      exercises = @strategy.reading_core_exercises(pages: pages_arr)
      verify_and_return exercises, klass: ::Ecosystem::Exercise
    end

    def reading_dynamic_exercises(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Ecosystem::Page
      exercises = @strategy.reading_dynamic_exercises(pages: pages_arr)
      verify_and_return exercises, klass: ::Ecosystem::Exercise
    end

    def homework_core_exercises(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Ecosystem::Page
      exercises = @strategy.homework_core_exercises(pages: pages_arr)
      verify_and_return exercises, klass: ::Ecosystem::Exercise
    end

    def homework_dynamic_exercises(pages:)
      pages_arr = verify_and_return [pages].flatten.compact, klass: ::Ecosystem::Page
      exercises = @strategy.homework_dynamic_exercises(pages: pages_arr)
      verify_and_return exercises, klass: ::Ecosystem::Exercise
    end

  end
end
