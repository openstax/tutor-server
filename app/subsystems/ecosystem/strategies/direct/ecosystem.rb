module Ecosystem
  module Strategies
    module Direct
      class Ecosystem < Entity

        wraps ::Content::Models::Ecosystem

        exposes :books, :chapters, :pages, :exercises, :pools
        exposes :create, :create!, from_class: ::Content::Models::Ecosystem

        alias_method :entity_books, :books
        def books
          entity_books.collect do |entity_book|
            ::Ecosystem::Book.new(strategy: entity_book)
          end
        end

        alias_method :entity_chapters, :chapters
        def chapters
          entity_chapters.collect do |entity_chapter|
            ::Ecosystem::Chapter.new(strategy: entity_chapter)
          end
        end

        def chapters_by_ids(*ids)
          id_indices = {}
          ids = ids.flatten
          ids.each_with_index do |id, index|
            integer_id = Integer(id) rescue nil
            next if integer_id.nil?

            id_indices[integer_id] = index
          end

          entity_chapters.where(id: ids).collect do |entity_chapter|
            ::Ecosystem::Chapter.new(strategy: entity_chapter)
          end.sort_by{ |ch| id_indices[ch.id] }
        end

        alias_method :entity_pages, :pages
        def pages
          entity_pages.collect do |entity_page|
            ::Ecosystem::Page.new(strategy: entity_page)
          end
        end

        def pages_by_ids(*ids)
          id_indices = {}
          ids = ids.flatten
          ids.each_with_index do |id, index|
            integer_id = Integer(id) rescue nil
            next if integer_id.nil?

            id_indices[integer_id] = index
          end

          entity_pages.where(id: ids).collect do |entity_page|
            ::Ecosystem::Page.new(strategy: entity_page)
          end.sort_by{ |pg| id_indices[pg.id] }
        end

        alias_method :entity_exercises, :exercises
        def exercises
          entity_exercises.collect do |entity_exercise|
            ::Ecosystem::Exercise.new(strategy: entity_exercise)
          end
        end

        def exercises_by_ids(*ids)
          id_indices = {}
          ids = ids.flatten
          ids.each_with_index do |id, index|
            integer_id = Integer(id) rescue nil
            next if integer_id.nil?

            id_indices[integer_id] = index
          end

          entity_exercises.where(id: ids).collect do |entity_exercise|
            ::Ecosystem::Exercise.new(strategy: entity_exercise)
          end.sort_by{ |ex| id_indices[ex.id] }
        end

        def exercises_by_numbers(*numbers)
          number_indices = {}
          numbers = numbers.flatten
          numbers.each_with_index do |number, index|
            integer_number = Integer(number) rescue nil
            next if integer_number.nil?

            number_indices[integer_number] = index
          end

          entity_exercises.where(number: numbers)
                          .group_by{ |ex| ex.number }
                          .collect do |number, entity_exercises|
            latest_exercise = entity_exercises.max_by{ |ex| ex.version }
            ::Ecosystem::Exercise.new(strategy: latest_exercise)
          end.sort_by{ |ex| number_indices[ex.number] }
        end

        def exercises_with_tags(*tags, match_count: tags.size)
          entity_exercises.reorder(nil)
                          .preload(exercise_tags: :tag)
                          .joins(exercise_tags: :tag)
                          .where(exercise_tags: {tag: {value: tags.flatten}})
                          .group(:id).having {
                            count(distinct(exercise_tags.tag.id)).gteq match_count
                          }.collect do |entity_exercise|
            ::Ecosystem::Exercise.new(strategy: entity_exercise)
          end
        end

        alias_method :entity_pools, :pools
        def pools
          entity_pools.collect do |entity_pool|
            ::Ecosystem::Pool.new(strategy: entity_pool)
          end
        end

        def reading_dynamic_pools(pages:)
          find_content_pools(pages: pages, type: :reading_dynamic)
        end

        def reading_try_another_pools(pages:)
          find_content_pools(pages: pages, type: :reading_try_another)
        end

        def homework_core_pools(pages:)
          find_content_pools(pages: pages, type: :homework_core)
        end

        def homework_dynamic_pools(pages:)
          find_content_pools(pages: pages, type: :homework_dynamic)
        end

        def practice_widget_pools(pages:)
          find_content_pools(pages: pages, type: :practice_widget)
        end

        protected

        def find_content_pools(pages:, type:)
          entity_pools.where(pool_type: Content::Models::Pool.pool_types[type],
                             content_page_id: pages.collect{ |pg| pg.id })
                      .collect do |entity_pool|
            ::Ecosystem::Pool.new(strategy: entity_pool)
          end
        end

      end
    end
  end
end
