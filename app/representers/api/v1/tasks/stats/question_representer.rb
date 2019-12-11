module Api::V1
  module Tasks
    module Stats
      class QuestionRepresenter < Roar::Decorator
        include Roar::JSON

        property :question_id,
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
                   extend: Api::V1::Tasks::Stats::AnswerRepresenter

        collection :answer_stats,
                   writeable: false,
                   readable: true,
                   extend: Api::V1::Tasks::Stats::AnswerStatsRepresenter
      end
    end
  end
end
