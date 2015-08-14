module Content
  class Map

    include Wrapper

    class << self
      # Create a new map or return nil if it cannot be created
      def create(from_ecosystems:, to_ecosystem:,
                 strategy_class: ::Content::Strategies::Generated::Map)
        from_arr = verify_and_return [from_ecosystems].flatten.compact,
                                     klass: ::Content::Ecosystem, error: ArgumentError
        to = verify_and_return to_ecosystem, klass: ::Content::Ecosystem, error: ArgumentError
        verify_and_return strategy_class.create(from_ecosystems: from_ecosystems,
                                                to_ecosystem: to_ecosystem),
                          klass: ::Content::Map, allow_nil: true
      end

      # Create a new map or error out if it cannot be created or is invalid
      def create!(from_ecosystems:, to_ecosystem:,
                  strategy_class: ::Content::Strategies::Generated::Map)
        from_arr = verify_and_return [from_ecosystems].flatten.compact,
                                     klass: ::Content::Ecosystem, error: ArgumentError
        to = verify_and_return to_ecosystem, klass: ::Content::Ecosystem, error: ArgumentError
        verify_and_return strategy_class.create!(from_ecosystems: from_ecosystems,
                                                 to_ecosystem: to_ecosystem), klass: ::Content::Map
      end

      # Find an existing map or return nil if it is missing
      def find(from_ecosystems:, to_ecosystem:,
               strategy_class: ::Content::Strategies::Generated::Map)
        from_arr = verify_and_return [from_ecosystems].flatten.compact,
                                     klass: ::Content::Ecosystem, error: ArgumentError
        to = verify_and_return to_ecosystem, klass: ::Content::Ecosystem, error: ArgumentError
        verify_and_return strategy_class.find(from_ecosystems: from_ecosystems,
                                              to_ecosystem: to_ecosystem),
                          klass: ::Content::Map, allow_nil: true
      end

      # Find an existing map or error out if it is missing or is invalid
      def find!(from_ecosystems:, to_ecosystem:,
                strategy_class: ::Content::Strategies::Generated::Map)
        from_arr = verify_and_return [from_ecosystems].flatten.compact,
                                     klass: ::Content::Ecosystem, error: ArgumentError
        to = verify_and_return to_ecosystem, klass: ::Content::Ecosystem, error: ArgumentError
        verify_and_return strategy_class.find!(from_ecosystems: from_ecosystems,
                                               to_ecosystem: to_ecosystem), klass: ::Content::Map
      end
    end

    # Returns a hash that groups the given exercises by their equivalent pages in the to_ecosystem
    def group_exercises_by_pages(exercises:)
      ex_arr = verify_and_return [exercises].flatten.compact, klass: ::Content::Exercise,
                                                              error: ArgumentError
      verify_and_return @strategy.group_exercises_by_pages(exercises: ex_arr), klass: Hash
    end

    def valid?
      !!@strategy.valid?
    end

  end
end
