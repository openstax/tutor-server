class Content::Ecosystem

  def initialize(strategy:)
    @strategy = strategy
  end

  def uuid
    uuid = @strategy.uuid

    raise_collection_class_error(
      collection: [uuid],
      klass:      Content::Ecosystem::Uuid,
      error:      Content::Ecosystem::StrategyError
    )

    uuid
  end

  def books
    books = @strategy.books

    raise_collection_class_error(
      collection: books,
      klass:      Content::Ecosystem::Book,
      error:      Content::Ecosystem::StrategyError
    )

    books
  end

  def exercises
    exercises = @strategy.exercises

    raise_collection_class_error(
      collection: exercises,
      klass:      Content::Ecosystem::Exercise,
      error:      Content::Ecosystem::StrategyError
    )

    exercises
  end

  def reading_core_exercises(pages:)
    pages_arr = Array(pages).flatten.compact

    raise_collection_class_error(
      collection: pages_arr,
      klass:      Content::Ecosystem::Page,
      error:      ArgumentError
    )

    exercises = @strategy.reading_core_exercises(pages: pages_arr)

    raise_collection_class_error(
      collection: exercises,
      klass:      Content::Ecosystem::Exercise,
      error:      Content::Ecosystem::StrategyError
    )

    exercises
  end

  private

  def raise_collection_class_error(collection:, klass:, error:)
    raise error if collection.detect{|obj| !obj.is_a? klass}
  end
end
