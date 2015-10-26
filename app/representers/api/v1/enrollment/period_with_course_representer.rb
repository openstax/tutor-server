module Api::V1::Enrollment
  class PeriodWithCourseRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    nested :course do
      property :id,
               type: String,
               getter: ->(*) { course.id },
               readable: true,
               writeable: false,
               schema_info: { required: true }

      property :name,
               type: String,
               getter: ->(*) { course.name },
               readable: true,
               writeable: false,
               schema_info: { required: true }
    end

    nested :period do
      property :id,
               type: String,
               readable: true,
               writeable: false,
               schema_info: { required: true }

      property :name,
               type: String,
               readable: true,
               writeable: false,
               schema_info: { required: true }
    end

  end
end
