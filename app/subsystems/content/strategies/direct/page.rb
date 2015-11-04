module Content
  module Strategies
    module Direct
      class Page < Entity

        wraps ::Content::Models::Page

        exposes :chapter, :reading_dynamic_pool, :reading_try_another_pool, :homework_core_pool,
                :homework_dynamic_pool, :practice_widget_pool, :all_exercises_pool,
                :exercises, :tags, :los, :aplos, :url, :uuid, :version, :cnx_id, :title, :content,
                :book_location, :is_intro?, :fragments, :snap_labs

        alias_method :entity_chapter, :chapter
        def chapter
          ::Content::Chapter.new(strategy: entity_chapter)
        end

        alias_method :entity_reading_dynamic_pool, :reading_dynamic_pool
        def reading_dynamic_pool
          ::Content::Pool.new(strategy: entity_reading_dynamic_pool)
        end

        alias_method :entity_reading_try_another_pool, :reading_try_another_pool
        def reading_try_another_pool
          ::Content::Pool.new(strategy: entity_reading_try_another_pool)
        end

        alias_method :entity_homework_core_pool, :homework_core_pool
        def homework_core_pool
          ::Content::Pool.new(strategy: entity_homework_core_pool)
        end

        alias_method :entity_homework_dynamic_pool, :homework_dynamic_pool
        def homework_dynamic_pool
          ::Content::Pool.new(strategy: entity_homework_dynamic_pool)
        end

        alias_method :entity_practice_widget_pool, :practice_widget_pool
        def practice_widget_pool
          ::Content::Pool.new(strategy: entity_practice_widget_pool)
        end

        alias_method :entity_all_exercises_pool, :all_exercises_pool
        def all_exercises_pool
          ::Content::Pool.new(strategy: entity_all_exercises_pool)
        end

        alias_method :entity_exercises, :exercises
        def exercises
          entity_exercises.collect do |entity_exercise|
            ::Content::Exercise.new(strategy: entity_exercise)
          end
        end

        alias_method :entity_tags, :tags
        def tags
          entity_tags.collect{ |et| ::Content::Tag.new(strategy: et) }
        end

        alias_method :entity_los, :los
        def los
          entity_los.collect{ |el| ::Content::Tag.new(strategy: el) }
        end

        alias_method :entity_aplos, :aplos
        def aplos
          entity_aplos.collect{ |ea| ::Content::Tag.new(strategy: ea) }
        end

        alias_method :string_uuid, :uuid
        def uuid
          ::Content::Uuid.new(string_uuid)
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
