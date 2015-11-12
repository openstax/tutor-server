module Api::V1::Courses::Cc::Student

  class ExerciseRepresenter < ::Roar::Decorator

    include ::Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             readable: true,
             writeable: false,
             schema_info: {
               required: true
             }

    property :is_completed,
             writeable: false,
             readable: true,
             schema_info: {
               type: 'boolean',
               required: true
             }

    property :is_correct,
             writeable: false,
             readable: true,
             schema_info: {
               type: 'boolean',
               required: true
             }

  end

end
