module Ecosystem
  module Strategies
    module Direct
      class Page < Entity

        wraps ::Content::Models::Page

        exposes :chapter, :url, :uuid, :version, :title, :content, :book_location, :is_intro?,
                :fragments, :reading_dynamic_pool, :reading_try_another_pool,
                :homework_core_pool, :homework_dynamic_pool, :practice_widget_pool

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

        def tags
          repository.tags.collect{ |t| t.value }
        end

        def los
          repository.los.collect{ |t| t.value }
        end

        def aplos
          repository.aplos.collect{ |t| t.value }
        end

        def toc
          {
            url: url,
            uuid: uuid,
            version: version,
            title: title,
            book_location: book_location,
            is_intro: is_intro
          }
        end

        def related_content(title: nil, book_location: nil)
          title ||= self.title
          book_location ||= self.book_location
          { title: title, book_location: book_location }
        end

      end
    end
  end
end
