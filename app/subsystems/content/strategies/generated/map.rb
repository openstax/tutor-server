module Content
  module Strategies
    module Generated
      class Map

        attr_accessor :exercise_id_to_page_map, :page_id_to_page_map,
                      :page_id_to_pool_type_exercises_map, :is_valid, :validity_error_message

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
          maps = find_or_create_maps(from_ecosystems: from_ecosystems, to_ecosystem: to_ecosystem)

          cache_merged_maps(maps: maps)

          cache_merged_map_validity(maps: maps)
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

        def wrap_hash(hash:)
          wrapped_hash = {}

          hash.each do |key, value|
            wrapped_value = case value
            when Hash
              wrap_hash hash: value
            when ::Content::Models::Exercise
              ::Content::Exercise.new(strategy: value.wrap)
            when ::Content::Models::Page
              ::Content::Page.new(strategy: value.wrap)
            else
              raise ArgumentError, "Cannot wrap #{value.class.name}", caller
            end

            merged_hash[key] = wrapped_value
          end
        end

        def cache_merged_maps(maps:)
          @page_id_to_page_map = wrap_hash(hash: maps.map(&:page_id_to_page_map).reduce(&:merge))
          @exercise_id_to_page_map = \
            wrap_hash(hash: maps.map(&:exercise_id_to_page_map).reduce(&:merge))
          @page_id_to_pool_type_exercises_map = \
            wrap_hash(hash: maps.map(&:page_id_to_pool_type_exercises_map).reduce(&:merge))
        end

        def cache_merged_map_validity(maps:)
          invalid_maps = maps.reject(&:is_valid)

          @is_valid = invalid_maps.none?

          @validity_error_message = invalid_maps.map do |ecosystem_map|
            "Invalid mapping: #{ecosystem_map.from_ecosystem.title} => #{
              ecosystem_map.to_ecosystem.title}. Errors: [#{
              ecosystem_map.validity_error_messages.join(", ")}]"
          end.join("\n")
        end

      end
    end
  end
end
