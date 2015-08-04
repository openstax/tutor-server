module Ecosystem
  module Strategies
    module Direct
      class Ecosystem < Entity

        wraps ::Content::Models::Ecosystem

        exposes :books
        exposes :create, :create!, from_class: ::Content::Models::Ecosystem

        alias_method :entity_books, :books
        def books
          entity_books.collect do |entity_book|
            ::Ecosystem::Book.new(strategy: entity_book)
          end
        end

      end
    end
  end
end
