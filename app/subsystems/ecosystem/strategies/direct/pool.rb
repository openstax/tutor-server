module Ecosystem
  module Strategies
    module Direct
      class Pool < Entity

        wraps ::Content::Models::Pool

        exposes :type, :exercise_ids, :exercises

        def uuid
          ::Ecosystem::Uuid.new(repository.uuid)
        end

      end
    end
  end
end
