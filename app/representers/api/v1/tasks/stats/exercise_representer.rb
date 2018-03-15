module Api::V1
  module Tasks
    module Stats
      class ExerciseRepresenter < Roar::Decorator

        include Roar::JSON

        property :content,
                 type: Object,
                 writeable: false,
                 readable: true,
                 getter: ->(*) { respond_to?(:content_hash) ? content_hash : content }

        collection :question_stats,
                   writeable: false,
                   readable: true,
                   extend: Api::V1::Tasks::Stats::QuestionRepresenter

        property :average_step_number,
                 type: Float,
                 writeable: false,
                 readable: true

      end
    end
  end
end
