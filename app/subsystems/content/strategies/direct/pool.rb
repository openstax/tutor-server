module Content
  module Strategies
    module Direct
      class Pool < Entity

        wraps ::Content::Models::Pool

        exposes :type, :exercise_ids, :exercises

        def uuid
          repository.uuid.nil? ? nil : ::Content::Uuid.new(repository.uuid)
        end

        alias_method :entity_exercises, :exercises
        def exercises
          entity_exercises.collect do |entity_exercise|
            ::Content::Exercise.new(strategy: entity_exercise)
          end
        end

      end
    end
  end
end
