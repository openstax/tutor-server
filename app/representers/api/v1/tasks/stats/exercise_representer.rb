module Api::V1
  module Tasks
    module Stats
      class ExerciseRepresenter < Roar::Decorator

        include Roar::JSON

        property :content,
                 type: String,
                 writeable: false,
                 readable: true

        property :answered_count,
                 type: Integer,
                 writeable: false,
                 readable: true

        collection :answers,
                   writeable: false,
                   readable: true,
                   decorator: Api::V1::Tasks::Stats::AnswerRepresenter

      end
    end
  end
end
