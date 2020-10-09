module Api::V1

  class PracticeQuestionRepresenter < ::Roar::Decorator

    include Roar::JSON

    property :id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: { required: true }

    property :tasked_exercise_id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: { required: true }

    property :exercise_number,
             type: String,
             writeable: false,
             readable: true,
             schema_info: { required: true }

    property :exercise_version,
             type: String,
             writeable: false,
             readable: true,
             schema_info: { required: true }

    property :entity_role_id,
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
