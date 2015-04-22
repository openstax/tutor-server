module Api::V1
  module Tasks
    module Stats
      class ExerciseRepresenter < Roar::Decorator

        include Roar::JSON

        property :content,
                 as: :content_html,
                 writeable: false,
                 readable: true

        property :answered_count,
                 writeable: false,
                 readable: true,
                 getter: ->(*) {  }

        collection :answers,
                   writeable: false,
                   readable: true,
                   decorator: AnswerRepresenter

      end
    end
  end
end
