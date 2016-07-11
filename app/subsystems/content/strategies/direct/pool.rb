module Content
  module Strategies
    module Direct
      class Pool < Entity

        wraps ::Content::Models::Pool

        exposes :pool_types, from_class: ::Content::Models::Pool
        exposes :pool_type, :exercise_ids, :exercises, :empty?

        class << self
          alias_method :pool_types_map, :pool_types
          def pool_types
            pool_types_map.keys
          end
        end

        def uuid
          repository.uuid.nil? ? nil : ::Content::Uuid.new(repository.uuid)
        end

        alias_method :entity_exercises, :exercises
        def exercises(preload_tags: false)
          ex = entity_exercises
          ex = ex.preload(tags: :teks_tags) if preload_tags
          ex.map do |entity_exercise|
            ::Content::Exercise.new(strategy: entity_exercise)
          end
        end

        def exercise_ids
          repository.content_exercise_ids
        end

      end
    end
  end
end
