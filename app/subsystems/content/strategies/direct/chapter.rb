module Content
  module Strategies
    module Direct
      class Chapter < Entity

        wraps ::Content::Models::Chapter

        exposes :book, :pages, :exercises, :all_exercises_pool, :tutor_uuid, :title, :book_location

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

        alias_method :entity_exercises, :exercises
        def exercises
          entity_exercises.map do |entity_exercise|
            ::Content::Exercise.new(strategy: entity_exercise)
          end
        end

        alias_method :entity_all_exercises_pool, :all_exercises_pool
        def all_exercises_pool
          ::Content::Pool.new(strategy: entity_all_exercises_pool)
        end

        alias_method :string_tutor_uuid, :tutor_uuid
        def tutor_uuid
          ::Content::Uuid.new(string_tutor_uuid)
        end

      end
    end
  end
end
