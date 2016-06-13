module Content
  class Map

    include Wrapper

    class << self
      # Find or create an ecosystem map
      def find_or_create(from_ecosystems:, to_ecosystem:,
                         strategy_class: ::Content::Strategies::Generated::Map)
        from_arr = verify_and_return [from_ecosystems].flatten.compact, klass: ::Content::Ecosystem
        to = verify_and_return to_ecosystem, klass: ::Content::Ecosystem
        verify_and_return strategy_class.find_or_create(from_ecosystems: from_ecosystems,
                                                        to_ecosystem: to_ecosystem),
                          klass: ::Content::Map, allow_nil: true, error: StrategyError
      end

      # Find or create an ecosystem map or error out if it is invalid
      def find_or_create!(from_ecosystems:, to_ecosystem:,
                          strategy_class: ::Content::Strategies::Generated::Map)
        from_arr = verify_and_return [from_ecosystems].flatten.compact, klass: ::Content::Ecosystem
        to = verify_and_return to_ecosystem, klass: ::Content::Ecosystem
        verify_and_return strategy_class.find_or_create!(from_ecosystems: from_ecosystems,
                                                         to_ecosystem: to_ecosystem),
                          klass: ::Content::Map, error: StrategyError
      end
    end

    # Returns a hash that maps the given Content::Exercises' ids
    # to Content::Pages in the to_ecosystem
    def exercise_id_to_page_map
      map = verify_and_return @strategy.exercise_id_to_page_map,
                              klass: Hash, error: StrategyError
      verify_and_return map.keys, klass: Integer, error: StrategyError
      verify_and_return map.values.compact, klass: ::Content::Page, error: StrategyError
      map
    end

    # Returns a hash that maps the given Content::Pages' ids
    # to Content::Pages in the to_ecosystem
    def page_id_to_page_map
      map = verify_and_return @strategy.page_id_to_page_map,
                              klass: Hash, error: StrategyError
      verify_and_return map.keys, klass: Integer, error: StrategyError
      verify_and_return map.values.compact, klass: ::Content::Page, error: StrategyError
      map
    end

    # Returns a hash that maps the given Content::Pages' ids
    # to a map of Content::Pool types to Content::Exercises in the to_ecosystem
    def page_id_to_pool_type_exercises_map
      map = verify_and_return @strategy.page_id_to_pool_type_exercises_map,
                              klass: Hash, error: StrategyError
      verify_and_return map.keys, klass: Integer, error: StrategyError
      verify_and_return map.values, klass: Hash, error: StrategyError
      map.values.each do |pool_type_exercises_map|
        verify_and_return map.keys, klass: Symbol, error: StrategyError
        verify_and_return map.values, klass: ::Content::Exercise, error: StrategyError
      end
      map
    end

    # Asserts that the Ecosystems mapping makes sense
    def is_valid
      !!@strategy.is_valid
    end

    # To help debug mapping errors
    def validity_error_message
      verify_and_return @strategy.validity_error_message, klass: String, error: StrategyError
    end
  end
end
