module Content
  module Strategies
    module Direct
      class Ecosystem < Entity

        wraps ::Content::Models::Ecosystem

        exposes :books, :chapters, :pages, :exercises, :pools, :tags, :title, :created_at
        exposes :all, :create, :create!, :find, from_class: ::Content::Models::Ecosystem

        class << self
          alias_method :entity_all, :all
          def all
            entity_all.collect do |entity|
              ::Content::Ecosystem.new(strategy: entity)
            end
          end

          alias_method :entity_create, :create
          def create(title:)
            ::Content::Ecosystem.new(strategy: entity_create(title: title))
          end

          alias_method :entity_create!, :create!
          def create!(title:)
            ::Content::Ecosystem.new(strategy: entity_create!(title: title))
          end

          alias_method :entity_find, :find
          def find(*args)
            ::Content::Ecosystem.new(strategy: entity_find(*args))
          end

          def find_by_book_ids(*ids)
            books = ::Content::Models::Book.eager_load(:ecosystem).where(id: ids).to_a
            return if books.size < ids.size

            content_ecosystems = books.collect{ |bk| bk.ecosystem }.uniq
            return if content_ecosystems.size != 1

            strategy = new(content_ecosystems.first)
            ::Content::Ecosystem.new(strategy: strategy)
          end

          def find_by_chapter_ids(*ids)
            chapters = ::Content::Models::Chapter.eager_load(:ecosystem).where(id: ids).to_a
            return if chapters.size < ids.size

            content_ecosystems = chapters.collect{ |ch| ch.ecosystem }.uniq
            return if content_ecosystems.size != 1

            strategy = new(content_ecosystems.first)
            ::Content::Ecosystem.new(strategy: strategy)
          end

          def find_by_page_ids(*ids)
            pages = ::Content::Models::Page.eager_load(:ecosystem).where(id: ids).to_a
            return if pages.size < ids.size

            content_ecosystems = pages.collect{ |pg| pg.ecosystem }.uniq
            return if content_ecosystems.size != 1

            strategy = new(content_ecosystems.first)
            ::Content::Ecosystem.new(strategy: strategy)
          end

          def find_by_exercise_ids(*ids)
            exercises = ::Content::Models::Exercise.eager_load(:ecosystem).where(id: ids).to_a
            return if exercises.size < ids.size

            content_ecosystems = exercises.collect{ |ex| ex.ecosystem }.uniq
            return if content_ecosystems.size != 1

            strategy = new(content_ecosystems.first)
            ::Content::Ecosystem.new(strategy: strategy)
          end
        end

        def manifest
          sorted_books = books.sort_by{ |bk| [bk.uuid, bk.version] }
          sorted_exercises = exercises.sort_by{ |ex| [ex.number, ex.version] }
          hash = {
            ecosystem_title: title,
            book_uuids: sorted_books.collect(&:uuid),
            book_versions: sorted_books.collect(&:version),
            exercise_numbers: sorted_exercises.collect(&:number),
            exercise_versions: sorted_exercises.collect(&:version)
          }
          strategy = ::Content::Strategies::Generated::Manifest.new(hash: hash)
          ::Content::Manifest.new(strategy: strategy)
        end

        alias_method :entity_books, :books
        def books
          entity_books.collect do |entity_book|
            ::Content::Book.new(strategy: entity_book)
          end
        end

        alias_method :entity_chapters, :chapters
        def chapters
          entity_chapters.collect do |entity_chapter|
            ::Content::Chapter.new(strategy: entity_chapter)
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
            ::Content::Chapter.new(strategy: entity_chapter)
          end.sort_by{ |ch| id_indices[ch.id] }
        end

        alias_method :entity_pages, :pages
        def pages(preload: nil)
          preload_args = case preload
                         when :for_clues
                           [:all_exercises_pool, {chapter: :all_exercises_pool}]
                         else
                           nil
                         end
          ep = entity_pages
          ep = ep.preload(preload_args) unless preload_args.nil?
          ep.collect do |entity_page|
            ::Content::Page.new(strategy: entity_page)
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
            ::Content::Page.new(strategy: entity_page)
          end.sort_by{ |pg| id_indices[pg.id] }
        end

        alias_method :entity_exercises, :exercises
        def exercises
          entity_exercises.collect do |entity_exercise|
            ::Content::Exercise.new(strategy: entity_exercise)
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
            ::Content::Exercise.new(strategy: entity_exercise)
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
            ::Content::Exercise.new(strategy: latest_exercise)
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
            ::Content::Exercise.new(strategy: entity_exercise)
          end
        end

        alias_method :entity_pools, :pools
        def pools
          entity_pools.collect do |entity_pool|
            ::Content::Pool.new(strategy: entity_pool)
          end
        end

        def reading_dynamic_pools(pages:)
          find_pools(pages: pages, type: :reading_dynamic)
        end

        def reading_try_another_pools(pages:)
          find_pools(pages: pages, type: :reading_try_another)
        end

        def homework_core_pools(pages:)
          find_pools(pages: pages, type: :homework_core)
        end

        def homework_dynamic_pools(pages:)
          find_pools(pages: pages, type: :homework_dynamic)
        end

        def practice_widget_pools(pages:)
          find_pools(pages: pages, type: :practice_widget)
        end

        alias_method :entity_tags, :tags
        def tags
          entity_tags.collect do |entity_tag|
            ::Content::Tag.new(strategy: entity_tag)
          end
        end

        def tags_by_values(*values)
          value_indices = {}
          values = values.flatten
          values.each_with_index do |value, index|
            value_indices[value.to_s] = index
          end

          entity_tags.where(value: values).collect do |entity_tag|
            ::Content::Tag.new(strategy: entity_tag)
          end.sort_by{ |tag| value_indices[tag.value.to_s] }
        end

        alias_method :imported_at, :created_at

        protected

        def find_pools(pages:, type:)
          page_ids = pages.collect(&:id)
          pool_method_name = "#{type.to_s}_pool".to_sym

          entity_pages.where(id: page_ids)
                      .joins(pool_method_name)
                      .eager_load(pool_method_name).collect do |entity_page|
            entity_pool = entity_page.send(pool_method_name)
            ::Content::Pool.new(strategy: entity_pool)
          end
        end

      end
    end
  end
end
