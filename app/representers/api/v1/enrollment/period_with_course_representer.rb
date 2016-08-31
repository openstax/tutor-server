module Api::V1::Enrollment

  class Teacher < Roar::Decorator
    include Roar::JSON

    property :name,
             readable: true,
             writeable: false,
             type: String

    property :first_name,
             readable: true,
             writeable: false,
             type: String

    property :last_name,
             readable: true,
             writeable: false,
             type: String
  end

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

      collection :teachers,
                 readable: true,
                 getter: ->(*) { teacher_roles.map{|role| role} },
                 writeable: false,
                 extend: Teacher
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
