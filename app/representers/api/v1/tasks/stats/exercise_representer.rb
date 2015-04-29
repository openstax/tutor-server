module Api::V1
  module Tasks
    module Stats
      class ExerciseRepresenter < Roar::Decorator

        include Roar::JSON

        property :content_json,
                 type: String,
                 writeable: false,
                 readable: true

        property :answered_count,
                 type: Integer,
                 writeable: false,
                 readable: true

      end
    end
  end
end
