module Ecosystem
  module Strategies
    class Direct < Entity

      wraps ::Ecosystem::Models::Ecosystem

      exposes :books

      exposes :create, :create!, from_class: ::Ecosystem::Models::Ecosystem

      alias_method :entity_books, :books
      def books
        entity_books.collect do |entity_book|
          ::Ecosystem::Book.new(strategy: entity_book)
        end
      end

    end
  end
end
