module Content
  class Map

    include Wrapper

    class << self
      # Create a new map or return nil if it cannot be created
      def create(from_ecosystems:, to_ecosystem:,
                 strategy_class: ::Content::Strategies::Generated::Map)
        from_arr = verify_and_return [from_ecosystems].flatten.compact, klass: ::Content::Ecosystem
        to = verify_and_return to_ecosystem, klass: ::Content::Ecosystem, error: ArgumentError
        verify_and_return strategy_class.create(from_ecosystems: from_ecosystems,
                                                to_ecosystem: to_ecosystem),
                          klass: ::Content::Map, allow_nil: true, error: ::Content::StrategyError
      end

      # Create a new map or error out if it cannot be created or is invalid
      def create!(from_ecosystems:, to_ecosystem:,
                  strategy_class: ::Content::Strategies::Generated::Map)
        from_arr = verify_and_return [from_ecosystems].flatten.compact, klass: ::Content::Ecosystem
        to = verify_and_return to_ecosystem, klass: ::Content::Ecosystem, error: ArgumentError
        verify_and_return strategy_class.create!(from_ecosystems: from_ecosystems,
                                                 to_ecosystem: to_ecosystem),
                          klass: ::Content::Map, error: ::Content::StrategyError
      end

      # Find an existing map or return nil if it is missing
      def find(from_ecosystems:, to_ecosystem:,
               strategy_class: ::Content::Strategies::Generated::Map)
        from_arr = verify_and_return [from_ecosystems].flatten.compact, klass: ::Content::Ecosystem
        to = verify_and_return to_ecosystem, klass: ::Content::Ecosystem, error: ArgumentError
        verify_and_return strategy_class.find(from_ecosystems: from_ecosystems,
                                              to_ecosystem: to_ecosystem),
                          klass: ::Content::Map, allow_nil: true, error: ::Content::StrategyError
      end

      # Find an existing map or error out if it is missing or is invalid
      def find!(from_ecosystems:, to_ecosystem:,
                strategy_class: ::Content::Strategies::Generated::Map)
        from_arr = verify_and_return [from_ecosystems].flatten.compact, klass: ::Content::Ecosystem
        to = verify_and_return to_ecosystem, klass: ::Content::Ecosystem, error: ArgumentError
        verify_and_return strategy_class.find!(from_ecosystems: from_ecosystems,
                                               to_ecosystem: to_ecosystem),
                          klass: ::Content::Map, error: ::Content::StrategyError
      end
    end

    # Returns an array of ::Content::Page's that correspond to the given array of
    # ::Content::Exercises, mapped to the to_ecosystem
    def map_exercises_to_pages(exercises:)
      ex_arr = verify_and_return [exercises].flatten.compact, klass: ::Content::Exercise
      verify_and_return @strategy.map_exercises_to_pages(exercises: ex_arr),
                        klass: ::Content::Page, error: ::Content::StrategyError
    end

    def valid?
      !!@strategy.valid?
    end

  end
end
