module Api::V1
  module Tasks
    module Stats
      class AnswerRepresenter < Roar::Decorator

        include Roar::JSON

        property :id,
                 type: String,
                 writeable: false,
                 readable: true

        property :selected_count,
                 type: Integer,
                 writeable: false,
                 readable: true

      end
    end
  end
end
