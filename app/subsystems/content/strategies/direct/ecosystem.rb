module Content
  module Strategies
    module Direct
      class Ecosystem < Entity

        wraps ::Content::Models::Ecosystem

        exposes :books, :chapters, :pages, :exercises, :pools, :tags, :tutor_uuid,
                :title, :comments, :created_at, :deletable?, :manifest_hash
        exposes :all, :create, :create!, :find, :deletable?,
                from_class: ::Content::Models::Ecosystem

        def to_model
          repository
        end

        class << self
          alias_method :entity_all, :all
          def all
            entity_all.map do |entity|
              ::Content::Ecosystem.new(strategy: entity)
            end
          end

          alias_method :entity_create, :create
          def create(comments:)
            ::Content::Ecosystem.new(strategy: entity_create(comments: comments))
          end

          alias_method :entity_create!, :create!
          def create!(comments:)
            ::Content::Ecosystem.new(strategy: entity_create!(comments: comments))
          end

          alias_method :entity_find, :find
          def find(*args)
            ::Content::Ecosystem.new(strategy: entity_find(*args))
          end

          def find_by_book_ids(*ids)
            books = ::Content::Models::Book.eager_load(:ecosystem).where(id: ids).to_a
            return if books.size < ids.size

            content_ecosystems = books.map(&:ecosystem).uniq
            return if content_ecosystems.size != 1

            strategy = new(content_ecosystems.first)
            ::Content::Ecosystem.new(strategy: strategy)
          end

          def find_by_chapter_ids(*ids)
            chapters = ::Content::Models::Chapter.eager_load(:ecosystem).where(id: ids).to_a
            return if chapters.size < ids.size

            content_ecosystems = chapters.map(&:ecosystem).uniq
            return if content_ecosystems.size != 1

            strategy = new(content_ecosystems.first)
            ::Content::Ecosystem.new(strategy: strategy)
          end

          def find_by_page_ids(*ids)
            pages = ::Content::Models::Page.eager_load(:ecosystem).where(id: ids).to_a
            return if pages.size < ids.size

            content_ecosystems = pages.map(&:ecosystem).uniq
            return if content_ecosystems.size != 1

            strategy = new(content_ecosystems.first)
            ::Content::Ecosystem.new(strategy: strategy)
          end

          def find_by_exercise_ids(*ids)
            exercises = ::Content::Models::Exercise.eager_load(:ecosystem).where(id: ids).to_a
            return if exercises.size < ids.size

            content_ecosystems = exercises.map(&:ecosystem).uniq
            return if content_ecosystems.size != 1

            strategy = new(content_ecosystems.first)
            ::Content::Ecosystem.new(strategy: strategy)
          end
        end

        def manifest
          strategy = ::Content::Strategies::Generated::Manifest.new(manifest_hash)
          ::Content::Manifest.new(strategy: strategy)
        end

        alias_method :entity_books, :books
        def books(preload: false)
          books = repository.books
          books = books.preloaded if preload
          books.map{ |book| ::Content::Book.new(strategy: book.wrap) }
        end

        alias_method :entity_chapters, :chapters
        def chapters
          entity_chapters.map do |entity_chapter|
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

          entity_chapters.where(id: ids).map do |entity_chapter|
            ::Content::Chapter.new(strategy: entity_chapter)
          end.sort_by{ |ch| id_indices[ch.id] }
        end

        alias_method :entity_pages, :pages
        def pages
          entity_pages.map do |entity_page|
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

          entity_pages.where(id: ids).map do |entity_page|
            ::Content::Page.new(strategy: entity_page)
          end.sort_by{ |pg| id_indices[pg.id] }
        end

        alias_method :entity_exercises, :exercises
        def exercises
          entity_exercises.map do |entity_exercise|
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

          entity_exercises.where(id: ids).map do |entity_exercise|
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
                          .group_by(&:number)
                          .map do |number, entity_exercises|
            latest_exercise = entity_exercises.max_by{ |ex| ex.version }
            ::Content::Exercise.new(strategy: latest_exercise)
          end.sort_by{ |ex| number_indices[ex.number] }
        end

        def exercises_with_tags(*tags, pages: nil, match_count: tags.size)
          exercises = entity_exercises.reorder(nil)
                                      .preload(exercise_tags: :tag)
                                      .joins(exercise_tags: :tag)
                                      .where(exercise_tags: {tag: {value: tags.flatten}})
                                      .group(:id).having do
            count(distinct(exercise_tags.tag.id)).gteq match_count
          end
          exercises = exercises.where(content_page_id: [pages].flatten.map(&:id)) unless pages.nil?

          exercises.map{ |entity_exercise| ::Content::Exercise.new(strategy: entity_exercise) }
        end

        alias_method :entity_pools, :pools
        def pools
          entity_pools.map do |entity_pool|
            ::Content::Pool.new(strategy: entity_pool)
          end
        end

        def reading_dynamic_pools(pages:)
          find_pools(pages: pages, type: :reading_dynamic)
        end

        def reading_context_pools(pages:)
          find_pools(pages: pages, type: :reading_context)
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

        def concept_coach_pools(pages:)
          find_pools(pages: pages, type: :concept_coach)
        end

        def all_exercises_pools(pages:)
          find_pools(pages: pages, type: :all_exercises)
        end

        alias_method :entity_tags, :tags
        def tags
          entity_tags.map do |entity_tag|
            ::Content::Tag.new(strategy: entity_tag)
          end
        end

        def tags_by_values(*values)
          value_indices = {}
          values = values.flatten
          values.each_with_index do |value, index|
            value_indices[value.to_s] = index
          end

          entity_tags.where(value: values).map do |entity_tag|
            ::Content::Tag.new(strategy: entity_tag)
          end.sort_by{ |tag| value_indices[tag.value.to_s] }
        end

        alias_method :string_tutor_uuid, :tutor_uuid
        def tutor_uuid
          ::Content::Uuid.new(string_tutor_uuid)
        end

        alias_method :imported_at, :created_at

        protected

        def find_pools(pages:, type:)
          page_ids = pages.map(&:id)
          pool_method_name = "#{type.to_s}_pool".to_sym

          entity_pages.where(id: page_ids)
                      .joins(pool_method_name)
                      .eager_load(pool_method_name).map do |entity_page|
            entity_page.send(pool_method_name)
          end
        end

      end
    end
  end
end
