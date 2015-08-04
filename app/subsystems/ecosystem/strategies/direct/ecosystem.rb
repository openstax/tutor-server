module Ecosystem
  module Strategies
    module Direct
      class Ecosystem < Entity

        wraps ::Content::Models::Ecosystem

        exposes :books, :pages, :exercises
        exposes :create, :create!, from_class: ::Content::Models::Ecosystem

        alias_method :entity_books, :books
        def books
          entity_books.collect do |entity_book|
            ::Ecosystem::Book.new(strategy: entity_book)
          end
        end

        alias_method :entity_pages, :pages
        def pages
          entity_pages.collect do |entity_page|
            ::Ecosystem::Page.new(strategy: entity_page)
          end
        end

        def pages_by_ids(ids)
          id_indices = {}
          ids.each_with_index do |id, index|
            id_indices[id] = index
          end

          pages.select{ |pg| !indices[pg.id].nil? }.sort_by{ |pg| indices[pg.id] }
        end

        alias_method :entity_exercises, :exercises
        def exercises
          entity_exercises.collect do |entity_exercise|
            ::Ecosystem::Exercise.new(strategy: entity_exercise)
          end
        end

        def exercises_by_ids(ids)
          id_indices = {}
          ids.each_with_index do |id, index|
            id_indices[id] = index
          end

          exercises.select{ |ex| !indices[ex.id].nil? }.sort_by{ |ex| indices[ex.id] }
        end

      end
    end
  end
end
