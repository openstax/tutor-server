module Content
  class Map

    include Wrapper

    class << self
      # Find or create an ecosystem map
      def find_or_create_by(from_ecosystems:, to_ecosystem:,
                            strategy_class: ::Content::Strategies::Generated::Map)
        from_arr = verify_and_return [from_ecosystems].flatten.compact, klass: ::Content::Ecosystem
        to = verify_and_return to_ecosystem, klass: ::Content::Ecosystem
        verify_and_return strategy_class.find_or_create_by(from_ecosystems: from_ecosystems,
                                                           to_ecosystem: to_ecosystem),
                          klass: ::Content::Map, allow_nil: true, error: StrategyError
      end

      # Find or create an ecosystem map or error out if it is invalid
      def find_or_create_by!(from_ecosystems:, to_ecosystem:,
                             strategy_class: ::Content::Strategies::Generated::Map)
        from_arr = verify_and_return [from_ecosystems].flatten.compact, klass: ::Content::Ecosystem
        to = verify_and_return to_ecosystem, klass: ::Content::Ecosystem
        verify_and_return strategy_class.find_or_create_by!(from_ecosystems: from_ecosystems,
                                                            to_ecosystem: to_ecosystem),
                          klass: ::Content::Map, error: StrategyError
      end
    end

    def to_ecosystem
      verify_and_return @strategy.to_ecosystem, klass: Content::Ecosystem, error: StrategyError
    end

    # Returns a hash that maps the given Content::Exercises
    # to Content::Pages in the to_ecosystem
    def map_exercises_to_pages(exercises:)
      ex_arr = verify_and_return [exercises].flatten.compact, klass: ::Content::Exercise
      map = verify_and_return @strategy.map_exercises_to_pages(exercises: ex_arr),
                              klass: Hash, error: StrategyError
      verify_and_return map.keys, klass: ::Content::Exercise, error: StrategyError
      verify_and_return map.values.compact, klass: ::Content::Page, error: StrategyError
      map
    end

    # Returns a hash that maps the given Content::Pages
    # to Content::Pages in the to_ecosystem
    def map_pages_to_pages(pages:)
      pg_arr = verify_and_return [pages].flatten.compact, klass: ::Content::Page
      map = verify_and_return @strategy.map_pages_to_pages(pages: pg_arr),
                              klass: Hash, error: StrategyError
      verify_and_return map.keys, klass: ::Content::Page, error: StrategyError
      verify_and_return map.values.compact, klass: ::Content::Page, error: StrategyError
      map
    end

    # Returns a hash that maps the given Content::Pages
    # to Content::Exercises in the to_ecosystem that are in a Content::Pool of the given type
    def map_pages_to_exercises(pages:, pool_type: :all_exercises)
      pg_arr = verify_and_return [pages].flatten.compact, klass: ::Content::Page
      map = verify_and_return @strategy.map_pages_to_exercises(pages: pg_arr,
                                                               pool_type: pool_type),
                              klass: Hash, error: StrategyError
      verify_and_return map.keys, klass: ::Content::Page, error: StrategyError
      verify_and_return map.values, klass: ::Content::Exercise, error: StrategyError
      map
    end

    # Asserts that the Ecosystem mapping makes sense
    def is_valid
      !!@strategy.is_valid
    end

    # An error message to help debug mapping errors
    def validity_error_message
      verify_and_return @strategy.validity_error_message, klass: String, error: StrategyError
    end
  end
end
