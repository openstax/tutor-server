module Content
  module Strategies
    module Generated
      class Map

        class << self
          def create(from_ecosystems:, to_ecosystem:)
            strategy = new(from_ecosystems: from_ecosystems, to_ecosystem: to_ecosystem)
            ::Content::Map.new(strategy: strategy)
          end

          def create!(from_ecosystems:, to_ecosystem:)
            create(from_ecosystems: from_ecosystems, to_ecosystem: to_ecosystem).tap do |map|
              raise(
                Content::MapInvalidError, "Cannot generate a valid ecosystem map from " +
                "[#{from_ecosystems.map(&:title).join(', ')}] to #{to_ecosystem.title} " +
                "diagnostic=(#{map.validity_diagnostic_message})"
              ) unless map.valid?
            end
          end

          alias_method :find, :create

          alias_method :find!, :create!
        end

        def initialize(from_ecosystems:, to_ecosystem:)
          @maps = make_maps(from_ecosystems: from_ecosystems, to_ecosystem: to_ecosystem)

          @page_id_to_pages_map, @exercise_id_to_page_map, @pool_type_page_id_to_exercises_map = \
            merge_maps(from_ecosystems: from_ecosystems, to_ecosystem: to_ecosystem)

          @is_valid, @validity_message = validate_maps(from_ecosystems: from_ecosystems, to_ecosystem: to_ecosystem)

        end


        def make_maps(from_ecosystems:, to_ecosystem:)
          existing = Content::Models::Map.where(content_from_ecosystem_id: from_ecosystems.map(&:id), content_to_ecosystem_id: to_ecosystem.id)

          existing_from_ecosystems_ids = existing.map(&:content_from_ecosystem_id)

          missing_from_ecosystems = from_ecosystems.reject do |ecosystem|
            existing_from_ecosystems_ids.include?(ecosystem.id)
          end

          new_maps = map_ecosystems(from_ecosystems: missing_from_ecosystems, to_ecosystem: to_ecosystem)

          existing + new_maps
        end

        def merge_maps
          page_id_to_pages_map = @maps.map(&:page_id_to_pages_map).reduce(&:merge)
          exercise_id_to_page_map = @maps.map(&:exercise_id_to_page_map).reduce(&:merge)
          pool_type_page_id_to_exercises_map = @maps.map(&:pool_type_page_id_to_exercises_map).reduce(&:merge)

          return page_id_to_pages_map, exercise_id_to_page_map,
                 pool_type_page_id_to_exercises_map
        end

        def map_ecosystems(from_ecosystems:, to_ecosystem:)

          # cache each
          ecosystems_maps = from_ecosystems.map do |from_ecosystem|

            # map each
            pages_map, exercises_map, pages_to_exercises_map = map_ecosystem(from_ecosystem: from_ecosystem, to_ecosystem: to_ecosystem)

            # save map
            Content::Models::Map.create(
              page_id_to_pages_map: pages_map,
              exercise_id_to_page_map: exercises_map,
              pool_type_page_id_to_exercises_map: pages_to_exercises_map,
              content_from_ecosystem_id: from_ecosystem.id, content_to_ecosystem_id: to_ecosystem.id
            )
          end
        end

        def map_ecosystem(from_ecosystem:, to_ecosystem:)

          exercises = from_ecosystem.exercises
          pages = from_ecosystem.pages

          page_ids = pages.map(&:id)
          exercise_ids = exercises.map(&:id)
          from_ecosystems_ids = [from_ecosystem.id]

          page_id_to_pages_map = make_page_id_to_pages_map_for_ecosystem(to_ecosystem)
          exercise_id_to_exercise_map = make_exercise_id_to_exercises_map_for_ecosystem(to_ecosystem)

          # map each
          pages_map = make_pages_to_pages_map(
            page_ids: page_ids,
            from_ecosystems_ids: from_ecosystems_ids,
            to_ecosystem: to_ecosystem,
            to_pages: page_id_to_pages_map
          )
          exercises_map = make_exercises_to_pages_map(
            exercise_ids: exercise_ids,
            from_ecosystems_ids: from_ecosystems_ids,
            to_ecosystem: to_ecosystem,
            to_pages: page_id_to_pages_map
          )
          pages_to_exercises_map = {}
          Content::Models::Pool.pool_types.keys.each do |pool_type|
            pool_type_sym = pool_type.to_sym

            pages_to_exercises_map[pool_type_sym] = make_pages_to_exercises_map(
              pages: pages,
              page_to_page_map: pages_map,
              pool_type: pool_type_sym,
              to_ecosystem: to_ecosystem,
              to_exercises: exercise_id_to_exercise_map
            )
          end

          return pages_map, exercises_map, pages_to_exercises_map
        end

        def map_pages_to_pages(pages:)
          page_ids = pages.map(&:id)

          initialize_page_id_to_pages_map_for_the_to_ecosystem

          mapped_pages = @page_id_to_pages_map.slice(*page_ids)
          unmapped_page_ids = page_ids - mapped_pages.keys

          return mapped_pages # if unmapped_page_ids.empty?

          pages_map = make_pages_to_pages_map(
            page_ids: unmapped_page_ids,
            from_ecosystems_ids: @from_ecosystems.map(&:id),
            to_ecosystem: @to_ecosystem,
            to_pages: @page_id_to_pages_map
          )

          @page_id_to_pages_map.merge!(pages_map)
          @page_id_to_pages_map.slice(*page_ids)
        end

        def map_exercises_to_pages(exercises:)
          exercise_ids = exercises.map(&:id)
          mapped_exercises = @exercise_id_to_page_map.slice(*exercise_ids)
          unmapped_exercise_ids = exercise_ids - mapped_exercises.keys

          return mapped_exercises # if unmapped_exercise_ids.empty?

          initialize_page_id_to_pages_map_for_the_to_ecosystem

          exercises_map = make_exercises_to_pages_map(
            exercise_ids: unmapped_exercise_ids,
            from_ecosystems_ids: @from_ecosystems.map(&:id),
            to_ecosystem: @to_ecosystem,
            to_pages: @page_id_to_pages_map
          )

          @exercise_id_to_page_map.merge!(exercises_map)
          @exercise_id_to_page_map.slice(*exercise_ids)
        end

        def map_pages_to_exercises(pages:, pool_type: :all_exercises)
          page_ids = pages.map(&:id)
          @pool_type_page_id_to_exercises_map[pool_type] ||= {}
          mapped_pages = @pool_type_page_id_to_exercises_map[pool_type].slice(*page_ids)
          unmapped_pages = pages.select{ |pg| mapped_pages[pg.id].nil? }

          return mapped_pages # if unmapped_pages.empty?

          @exercise_id_to_exercise_map ||= make_exercise_id_to_exercises_map_for_ecosystem(@to_ecosystem)

          page_to_page_map = map_pages_to_pages(pages: unmapped_pages)

          page_id_to_exercises_map_for_pool_type = make_pages_to_exercises_map(
            pages: unmapped_pages,
            page_to_page_map: page_to_page_map,
            pool_type: pool_type,
            to_ecosystem: @to_ecosystem,
            to_exercises: @exercise_id_to_exercise_map
          )

          @pool_type_page_id_to_exercises_map[pool_type].merge!(page_id_to_exercises_map_for_pool_type)
          @pool_type_page_id_to_exercises_map[pool_type].slice(*page_ids)
        end

        def valid?
          @is_valid
        end

        def validity_diagnostic_message
          @validity_message
        end

        protected

        def validate_maps
          is_valid = @maps.all?(&:is_valid)

          validity_messages = @maps.map do |ecosystem_map|
            if not ecosystem_map.is_valid
              "Mapping fails for #{ecosystem_map.from_ecosystem.title} to #{ecosystem_map.to_ecosystem.title} with #{ecosystem_map.validity_messages}"
            end
          end

          validity_message = validity_messages.compact.join(', ')

          return is_valid, validity_message
        end

        def initialize_page_id_to_pages_map_for_the_to_ecosystem
          @page_id_to_pages_map = make_page_id_to_pages_map_for_ecosystem(@to_ecosystem) if @page_id_to_pages_map.blank?
        end

        def make_page_id_to_pages_map_for_ecosystem(ecosystem)
          page_id_to_pages_map = ecosystem.pages.each_with_object({}) do |page, hash|
            hash[page.id] = page
          end

          return page_id_to_pages_map
        end

        def make_exercise_id_to_exercises_map_for_ecosystem(ecosystem)
          exercise_id_to_exercises_map = ecosystem.exercises.each_with_object({}) do |exercise, hash|
            hash[exercise.id] = exercise
          end

          return exercise_id_to_exercises_map
        end

        def make_pages_to_pages_map(page_ids:, from_ecosystems_ids:, to_ecosystem:, to_pages:)
          pages_map = {}
          to_pages ||= make_page_id_to_pages_map_for_ecosystem(to_ecosystem)

          page_to_page_map = Content::Models::Page
            .joins(tags: {same_value_tags: :pages})
            .where(tags: {
                     content_ecosystem_id: to_ecosystem.id,
                     tag_type: mapping_tag_types,
                     same_value_tags: {
                       content_ecosystem_id: from_ecosystems_ids,
                       tag_type: mapping_tag_types,
                       pages: {
                         id: page_ids
                       }
                     }
                   })
            .select{[Content::Models::Page.arel_table[Arel.star],
                     tags.same_value_tags.pages.id.as(:unmapped_page_id)]}
            .to_a.group_by(&:unmapped_page_id)

          page_to_page_map.each do |page_id, page_models|
            ecosystem_pages = page_models.map{ |pm| to_pages[pm.id] }.compact.uniq

            # It could happen in theory that a page maps to 2 or more pages,
            # but for now we don't handle that case
            # since it's hard to figure out what to do for the dashboard/scores
            pages_map[page_id] = ecosystem_pages.size == 1 ? ecosystem_pages.first : nil
          end

          return pages_map
        end

        def make_exercises_to_pages_map(exercise_ids:, from_ecosystems_ids:, to_ecosystem:, to_pages:)
          exercises_map = {}
          to_pages ||= make_page_id_to_pages_map_for_ecosystem(to_ecosystem)

          exercise_to_page_map = Content::Models::Page
            .joins(tags: {same_value_tags: :exercises})
            .where(tags: {
                     content_ecosystem_id: to_ecosystem.id,
                     tag_type: mapping_tag_types,
                     same_value_tags: {
                       content_ecosystem_id: from_ecosystems_ids,
                       tag_type: mapping_tag_types,
                       exercises: {
                         id: exercise_ids
                       }
                     }
                   })
            .select{[Content::Models::Page.arel_table[Arel.star],
                     tags.same_value_tags.exercises.id.as(:unmapped_exercise_id)]}
            .to_a.group_by(&:unmapped_exercise_id)

          exercise_to_page_map.each do |exercise_id, page_models|
            ecosystem_pages = page_models.map{ |pm| to_pages[pm.id] }.compact.uniq

            # Each exercise maps to the highest numbered page that shares a mapping tag with it
            exercises_map[exercise_id] = ecosystem_pages.max_by(&:book_location)
          end

          return exercises_map
        end

        def make_pages_to_exercises_map(pages:, page_to_page_map:, pool_type:, to_ecosystem:, to_exercises:)

          pool_type_page_id_to_exercises_map = {}
          page_ids = page_to_page_map.values.compact.map(&:id)

          to_exercises ||= make_exercise_id_to_exercises_map_for_ecosystem(to_ecosystem)

          pool_association = "#{pool_type}_pool".to_sym

          to_page_models = Content::Models::Page.where(id: page_ids)
                                                .joins(pool_association)
                                                .preload(pool_association)

          to_page_to_exercises_map = {}
          to_page_models.each do |to_page|
            pool = to_page.send(pool_association)
            exercises = pool.content_exercise_ids.map{ |ex_id| to_exercises[ex_id] }
            to_page_to_exercises_map[to_page.id] = exercises
          end

          pages.each do |page|
            to_page = page_to_page_map[page.id]
            exercises = to_page_to_exercises_map[to_page.try(:id)] || []
            pool_type_page_id_to_exercises_map[page.id] = exercises
          end

          return pool_type_page_id_to_exercises_map
        end

        def mapping_tag_types
          @mapping_tag_types ||= Content::Models::Tag::MAPPING_TAG_TYPES.map do |type|
            Content::Models::Tag.tag_types[type]
          end
        end

      end
    end
  end
end
