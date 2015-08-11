module Ecosystem
  module Strategies
    module Direct
      class Page < Entity

        wraps ::Content::Models::Page

        exposes :chapter, :reading_dynamic_pool, :reading_try_another_pool, :homework_core_pool,
                :homework_dynamic_pool, :practice_widget_pool, :exercises, :tags, :los, :aplos,
                :url, :uuid, :version, :cnx_id, :title, :content, :book_location, :is_intro?,
                :fragments

        alias_method :entity_chapter, :chapter
        def chapter
          ::Ecosystem::Chapter.new(strategy: entity_chapter)
        end

        alias_method :entity_reading_dynamic_pool, :reading_dynamic_pool
        def reading_dynamic_pool
          ::Ecosystem::Pool.new(strategy: entity_reading_dynamic_pool)
        end

        alias_method :entity_reading_try_another_pool, :reading_try_another_pool
        def reading_try_another_pool
          ::Ecosystem::Pool.new(strategy: entity_reading_try_another_pool)
        end

        alias_method :entity_homework_core_pool, :homework_core_pool
        def homework_core_pool
          ::Ecosystem::Pool.new(strategy: entity_homework_core_pool)
        end

        alias_method :entity_homework_dynamic_pool, :homework_dynamic_pool
        def homework_dynamic_pool
          ::Ecosystem::Pool.new(strategy: entity_homework_dynamic_pool)
        end

        alias_method :entity_practice_widget_pool, :practice_widget_pool
        def practice_widget_pool
          ::Ecosystem::Pool.new(strategy: entity_practice_widget_pool)
        end

        alias_method :entity_exercises, :exercises
        def exercises
          entity_exercises.collect do |entity_exercise|
            ::Ecosystem::Exercise.new(strategy: entity_exercise)
          end
        end

        alias_method :entity_tags, :tags
        def tags
          entity_tags.collect{ |et| ::Ecosystem::Tag.new(strategy: et) }
        end

        alias_method :entity_los, :los
        def los
          entity_los.collect{ |el| ::Ecosystem::Tag.new(strategy: el) }
        end

        alias_method :entity_aplos, :aplos
        def aplos
          entity_aplos.collect{ |ea| ::Ecosystem::Tag.new(strategy: ea) }
        end

        def related_content(title: nil, book_location: nil)
          title ||= is_intro? ? chapter.title : self.title
          book_location ||= self.book_location
          { title: title, book_location: book_location }
        end

      end
    end
  end
end
