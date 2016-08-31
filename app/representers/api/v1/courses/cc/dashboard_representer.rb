module Api::V1::Courses::Cc

  class DashboardRepresenter < ::Roar::Decorator

    include ::Roar::JSON

    class TaskBase < ::Roar::Decorator
      include Roar::JSON
      include Representable::Coercion

      property :id,
               type: String,
               readable: true,
               writeable: false

      property :title,
               type: String,
               readable: true,
               writeable: false

      property :opens_at,
               type: String,
               readable: true,
               writeable: false,
               getter: ->(*) { DateTimeUtilities.to_api_s(opens_at) }

      property :last_worked_at,
               type: String,
               readable: true,
               writeable: false,
               getter: ->(*) { DateTimeUtilities.to_api_s(last_worked_at) }

      property :task_type,
               as: :type,
               type: String,
               readable: true,
               writeable: false

      property :description,
               type: String,
               readable: true,
               writeable: false

      property :'completed?',
               as: :complete,
               readable: true,
               writeable: false,
               schema_info: { type: 'boolean' }
    end

    class Role < Roar::Decorator
      include Roar::JSON
      include Representable::Coercion

      property :id,
               readable: true,
               writeable: false,
               type: String

      property :type,
               readable: true,
               writeable: false,
               type: String
    end

    class Teacher < Roar::Decorator
      include Roar::JSON

      property :id,
               readable: true,
               writeable: false,
               type: String

      property :role_id,
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

    class Course < Roar::Decorator
      include Roar::JSON

      property :name,
               readable: true,
               writeable: false,
               type: String

      collection :teachers,
                 readable: true,
                 writeable: false,
                 extend: Teacher

      collection :periods,
                 readable: true,
                 writeable: false,
                 extend: Api::V1::Courses::Cc::Teacher::PeriodRepresenter
    end

    # Actual attributes below

    collection :tasks,
               readable: true,
               writeable: false,
               skip_render: ->(input:, **) {
                 input.task_type.to_s != 'concept_coach'
               },
               extend: TaskBase

    property :role,
             readable: true,
             writeable: false,
             extend: Role

    property :course,
             readable: true,
             writeable: false,
             extend: Course

    collection :chapters,
               readable: true,
               writeable: false,
               extend: Api::V1::Courses::Cc::Student::ChapterRepresenter

  end

end
