module Api::V1

  class PracticeQuestionRepresenter < ::Roar::Decorator

    include Roar::JSON

    property :id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: { required: true }

    property :tasks_tasked_exercise_id,
             as: :tasked_exercise_id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: { required: true }

    property :content_exercise_id,
             as: :exercise_id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: { required: true }

    property :available?,
             as: :available,
             writeable: false,
             readable: true,
             schema_info: { required: true, type: 'boolean' }

  end

end
