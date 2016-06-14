module Content
  module Strategies
    module Generated
      class Map

        attr_accessor :is_valid, :validity_error_message

        class << self
          def find_or_create(from_ecosystems:, to_ecosystem:)
            strategy = new(from_ecosystems: from_ecosystems, to_ecosystem: to_ecosystem)
            ::Content::Map.new(strategy: strategy)
          end

          def find_or_create!(from_ecosystems:, to_ecosystem:)
            find_or_create(from_ecosystems: from_ecosystems,
                           to_ecosystem: to_ecosystem).tap do |map|
              raise(::Content::MapInvalidError, map.validity_error_message) unless map.is_valid
            end
          end
        end

        def initialize(from_ecosystems:, to_ecosystem:)
          @to_ecosystem = to_ecosystem
          maps = find_or_create_maps(from_ecosystems: from_ecosystems, to_ecosystem: to_ecosystem)
          merge_maps(maps: maps)
        end

        # Returns a hash that maps the given Content::Exercises
        # to Content::Pages in the to_ecosystem
        def map_exercises_to_pages(exercises:)
          exercise_ids = exercises.map(&:id)
          page_ids = exercise_ids.map{ |ex_id| @exercise_id_to_page_id_map[ex_id] }
          pages_by_ids = to_ecosystem_pages_by_ids(*page_ids)

          exercise_to_page_map = {}

          exercises.each do |exercise|
            page_id = @exercise_id_to_page_id_map[exercise.id]
            exercise_to_page_map[exercise] = pages_by_ids[page_id]
          end

          exercise_to_page_map
        end

        # Returns a hash that maps the given Content::Pages
        # to Content::Pages in the to_ecosystem
        def map_pages_to_pages(pages:)
          from_page_ids = pages.map(&:id)
          to_page_ids = from_page_ids.map{ |pg_id| @page_id_to_page_id_map[pg_id] }
          pages_by_ids = to_ecosystem_pages_by_ids(*to_page_ids)

          page_to_page_map = {}

          pages.each do |page|
            to_page_id = @page_id_to_page_id_map[page.id]
            page_to_page_map[page] = pages_by_ids[to_page_id]
          end

          page_to_page_map
        end

        # Returns a hash that maps the given Content::Pages
        # to Content::Exercises in the to_ecosystem that are in a Content::Pool of the given type
        def map_pages_to_exercises(pages:, pool_type: :all_exercises)
          page_ids = pages.map(&:id)
          exercise_ids = page_ids.map do |pg_id|
            @page_id_to_pool_type_exercise_ids_map[pg_id][pool_type]
          end
          exercises_by_ids = to_ecosystem_exercises_by_ids(*exercise_ids)

          page_to_exercises_map = {}

          pages.each do |page|
            exercise_id = @page_id_to_pool_type_exercise_ids_map[page.id][pool_type]
            page_to_exercises_map[page] = exercises_by_ids[exercise_id]
          end

          page_to_exercises_map
        end

        protected

        def find_or_create_maps(from_ecosystems:, to_ecosystem:)
          existing_maps = Content::Models::Map.where(
            content_from_ecosystem_id: from_ecosystems.map(&:id),
            content_to_ecosystem_id: to_ecosystem.id
          )

          existing_from_ecosystems_ids = existing_maps.map(&:content_from_ecosystem_id)

          missing_from_ecosystems = from_ecosystems.reject do |ecosystem|
            existing_from_ecosystems_ids.include?(ecosystem.id)
          end

          new_maps = create_maps(
            from_ecosystems: missing_from_ecosystems, to_ecosystem: to_ecosystem
          )

          existing_maps + new_maps
        end

        def create_maps(from_ecosystems:, to_ecosystem:)
          from_ecosystems.map do |from_ecosystem|
            Content::Models::Map.create from_ecosystem: from_ecosystem, to_ecosystem: to_ecosystem
          end
        end

        def merge_maps(maps:)
          @page_id_to_page_id_map = maps.map(&:page_id_to_page_id_map).reduce(&:merge)
          @exercise_id_to_page_id_map = maps.map(&:exercise_id_to_page_id_map).reduce(&:merge)
          @page_id_to_pool_type_exercise_ids_map = maps.map(&:page_id_to_pool_type_exercise_ids_map)
                                                       .reduce(&:merge)
          merge_map_validities(maps: maps)
        end

        def merge_map_validities(maps:)
          invalid_maps = maps.reject(&:is_valid)

          @is_valid = invalid_maps.none?

          @validity_error_message = invalid_maps.map do |ecosystem_map|
            "Invalid mapping: #{ecosystem_map.from_ecosystem.title} => #{
              ecosystem_map.to_ecosystem.title}. Errors: [#{
              ecosystem_map.validity_error_messages.join(", ")}]"
          end.join("\n")
        end

        def to_ecosystem_exercises_by_ids(*exercise_ids)
          @to_exercises_map ||= {}

          unmapped_exercise_ids = exercise_ids.reject{ |ex_id| @to_exercises_map.has_key? ex_id }
          @to_exercises_map = @to_exercises_map.merge(
            @to_ecosystem.exercises_by_ids(*unmapped_exercise_ids).index_by(&:id)
          ) unless unmapped_exercise_ids.empty?

          @to_exercises_map.slice(*exercise_ids)
        end

        def to_ecosystem_pages_by_ids(*page_ids)
          @to_pages_map ||= {}

          unmapped_page_ids = page_ids.reject{ |page_id| @to_pages_map.has_key? page_id }
          @to_pages_map = @to_pages_map.merge(
            @to_ecosystem.pages_by_ids(*unmapped_page_ids).index_by(&:id)
          ) unless unmapped_page_ids.empty?

          @to_pages_map.slice(*page_ids)
        end

      end
    end
  end
end
