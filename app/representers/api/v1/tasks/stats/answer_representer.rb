module Api::V1
  module Tasks
    module Stats
      class AnswerRepresenter < Roar::Decorator

        include Roar::JSON

        property :content,
                 as: :content_html,
                 writeable: false,
                 readable: true

        property :correctness,
                 type: Float,
                 writeable: false,
                 readable: true,
                 schema_info: {
                   type: "number"
                 }

        property :selected_count,
                 type: Integer,
                 writeable: false,
                 readable: true,
                 getter: ->(*) {  }

      end
    end
  end
end
