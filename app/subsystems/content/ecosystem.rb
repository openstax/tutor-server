class Content::Ecosystem

  def initialize(strategy:)
    @strategy = strategy
  end

  def books
    books = @strategy.books

    raise StrategyError \
      if books.detect{|book| !book.is_a?(Book)}

    books
  end
end
