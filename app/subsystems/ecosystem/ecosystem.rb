module Ecosystem
  class Ecosystem

    def initialize(strategy:)
      @strategy = strategy
    end

    def uuid
      uuid = @strategy.uuid

      raise_collection_class_error(
        collection: [uuid],
        klass:      ::Ecosystem::Uuid,
        error:      ::Ecosystem::StrategyError
      )

      uuid
    end

    def books
      books = @strategy.books

      raise_collection_class_error(
        collection: books,
        klass:      ::Ecosystem::Book,
        error:      ::Ecosystem::StrategyError
      )

      books
    end

    def exercises
      exercises = @strategy.exercises

      raise_collection_class_error(
        collection: exercises,
        klass:      ::Ecosystem::Exercise,
        error:      ::Ecosystem::StrategyError
      )

      exercises
    end

    def reading_core_exercises(pages:)
      pages_arr = Array(pages).flatten.compact

      raise_collection_class_error(
        collection: pages_arr,
        klass:      ::Ecosystem::Page,
        error:      ArgumentError
      )

      exercises = @strategy.reading_core_exercises(pages: pages_arr)

      raise_collection_class_error(
        collection: exercises,
        klass:      ::Ecosystem::Exercise,
        error:      ::Ecosystem::StrategyError
      )

      exercises
    end

    def reading_dynamic_exercises(pages:)
      pages_arr = Array(pages).flatten.compact

      raise_collection_class_error(
        collection: pages_arr,
        klass:      ::Ecosystem::Page,
        error:      ArgumentError
      )

      exercises = @strategy.reading_dynamic_exercises(pages: pages_arr)

      raise_collection_class_error(
        collection: exercises,
        klass:      ::Ecosystem::Exercise,
        error:      ::Ecosystem::StrategyError
      )

      exercises
    end

    def homework_core_exercises(pages:)
      pages_arr = Array(pages).flatten.compact

      raise_collection_class_error(
        collection: pages_arr,
        klass:      ::Ecosystem::Page,
        error:      ArgumentError
      )

      exercises = @strategy.homework_core_exercises(pages: pages_arr)

      raise_collection_class_error(
        collection: exercises,
        klass:      ::Ecosystem::Exercise,
        error:      ::Ecosystem::StrategyError
      )

      exercises
    end

    def homework_dynamic_exercises(pages:)
      pages_arr = Array(pages).flatten.compact

      raise_collection_class_error(
        collection: pages_arr,
        klass:      ::Ecosystem::Page,
        error:      ArgumentError
      )

      exercises = @strategy.homework_dynamic_exercises(pages: pages_arr)

      raise_collection_class_error(
        collection: exercises,
        klass:      ::Ecosystem::Exercise,
        error:      ::Ecosystem::StrategyError
      )

      exercises
    end

    private

    def raise_collection_class_error(collection:, klass:, error:)
      raise error if collection.detect{|obj| !obj.is_a? klass}
    end

  end
end
