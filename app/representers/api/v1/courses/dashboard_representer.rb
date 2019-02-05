module Api::V1::Courses

  class DashboardRepresenter < ::Roar::Decorator

    include ::Roar::JSON

    class TaskBase < Roar::Decorator
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

      property :due_at,
               type: String,
               readable: true,
               writeable: false,
               getter: ->(*) { DateTimeUtilities.to_api_s(due_at) }

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

      property :completed?,
               as: :complete,
               readable: true,
               writeable: false,
               schema_info: { type: 'boolean' }

      property :withdrawn?,
               as: :is_deleted,
               readable: true,
               writeable: false,
               schema_info: {
                 type: 'boolean',
                 description: "Whether or not this task has been withdrawn by the teacher"
               }
    end

    class StepTaskBase < TaskBase
      property :completed_exercise_count,
               as: :complete_exercise_count,
               type: Integer,
               readable: true,
               writeable: false

      property :actual_and_placeholder_exercise_count,
               as: :exercise_count,
               type: Integer,
               readable: true,
               writeable: false
      property :accepted_late_at,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { DateTimeUtilities.to_api_s(accepted_late_at) }

      property :completed_accepted_late_exercise_count,
               type: Integer,
               readable: true,
               writeable: false

      property :completed_on_time_exercise_count,
               type: Integer,
               readable: true,
               writeable: false

      property :correct_on_time_exercise_count,
               type: Integer,
               readable: true,
               writeable: false,
               if: ->(*) { feedback_available? }

      property :correct_exercise_count,
               type: Integer,
               readable: true,
               writeable: false,
               if: ->(*) { feedback_available? }

      property :steps_count,
               type: Integer,
               readable: true,
               writeable: false

      property :completed_steps_count,
               type: Integer,
               readable: true,
               writeable: false

      property :completed_on_time_steps_count,
               type: Integer,
               readable: true,
               writeable: false

      property :completed_accepted_late_steps_count,
               type: Integer,
               readable: true,
               writeable: false
    end

    class ReadingTask < StepTaskBase
    end

    class HomeworkTask < StepTaskBase
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
    end

    # Actual attributes below

    collection :plans,
               readable: true,
               writeable: false,
               extend: ::Api::V1::TaskPlanRepresenter

    collection :tasks,
               readable: true,
               writeable: false,
               skip_render: ->(input:, **) do
                 !['reading','homework','external','event'].include?(input.task_type.to_s)
               end,
               extend: ->(input:, **) do
                 case input.task_type.to_s
                 when 'reading'
                   ReadingTask
                 when 'homework'
                   HomeworkTask
                 else
                   TaskBase
                 end
               end

    property :role,
             readable: true,
             writeable: false,
             extend: Role

    property :course,
             readable: true,
             writeable: false,
             extend: Course

    property :all_tasks_are_ready,
             readable: true,
             writeable: false

    collection :research_surveys,
               readable: true,
               writeable: false,
               extend: ::Api::V1::ResearchSurveyRepresenter

  end

end
