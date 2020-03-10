module Api::V1
  module Tasks
    module Stats
      class AnswerRepresenter < Roar::Decorator

        include Roar::JSON

        collection :students,
                   type: Object,
                   writeable: false,
                   readable: true

        property :free_response,
                 type: String,
                 writeable: false,
                 readable: true

        property :answer_id,
                 type: String,
                 writeable: false,
                 readable: true

      end
    end
  end
end
