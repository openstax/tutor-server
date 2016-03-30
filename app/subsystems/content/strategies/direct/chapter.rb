module Content
  module Strategies
    module Direct
      class Chapter < Entity

        wraps ::Content::Models::Chapter

        exposes :book, :pages, :all_exercises_pool, :title, :book_location

        alias_method :entity_book, :book
        def book
          ::Content::Book.new(strategy: entity_book)
        end

        alias_method :entity_pages, :pages
        def pages
          entity_pages.map do |entity_page|
            ::Content::Page.new(strategy: entity_page)
          end
        end

        alias_method :entity_all_exercises_pool, :all_exercises_pool
        def all_exercises_pool
          ::Content::Pool.new(strategy: entity_all_exercises_pool)
        end

      end
    end
  end
end
