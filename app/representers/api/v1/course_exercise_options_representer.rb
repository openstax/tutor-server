module Api::V1
  class CourseExerciseOptionsRepresenter < Roar::Decorator

    include Roar::JSON

    property :exercise_id,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :is_excluded,
             readable: true,
             writeable: true,
             schema_info: {
               required: true,
               type: 'boolean'
             }

  end
end
