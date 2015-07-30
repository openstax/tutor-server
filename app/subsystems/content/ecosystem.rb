class Content::Ecosystem

  def initialize(strategy:)
    @strategy = strategy
  end

  def uuid
    uuid = @strategy.uuid

    raise StrategyError \
      unless uuid.is_a? Uuid

    uuid
  end

  def books
    books = @strategy.books

    raise StrategyError \
      if books.detect{|obj| !obj.is_a?(Book)}

    books
  end

  def exercises
    exercises = @strategy.exercises

    raise StrategyError \
      if exercises.detect{|obj| !obj.is_a?(Exercise)}

    exercises
  end

end
