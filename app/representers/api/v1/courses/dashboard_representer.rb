module Api::V1::Courses

  class DashboardRepresenter < ::Roar::Decorator

    include ::Roar::JSON

    class Base < Roar::Decorator
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

    end

    class Plan < Base

      property :trouble,
               as: :is_trouble,
               readable: true,
               writeable: false,
               getter: ->(*) { false },
               schema_info: { type: 'boolean' }
        # ^^^^^ REPLACE with real value once spec for calculating it's available

      property :type,
               type: String,
               readable: true,
               writeable: false


      property :is_publish_requested,
               readable: true,
               writeable: true,
               getter: ->(*) { is_publish_requested? },
               schema_info: { type: 'boolean' }

      property :published_at,
               type: String,
               readable: true,
               writeable: false,
               getter: ->(*) { DateTimeUtilities.to_api_s(published_at) }

      property :publish_last_requested_at,
               type: String,
               readable: true,
               writeable: false,
               getter: ->(*) { DateTimeUtilities.to_api_s(publish_last_requested_at) }

      property :publish_job_uuid,
               type: String,
               readable: true,
               writeable: false

      collection :tasking_plans,
                 readable: true,
                 writeable: false,
                 decorator: Api::V1::TaskingPlanRepresenter

    end

    class TaskBase < Base

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

      property :'completed?',
               as: :complete,
               readable: true,
               writeable: false,
               schema_info: { type: 'boolean' }
    end

    class ReadingTask < TaskBase
      property :actual_and_placeholder_exercise_count,
               as: :exercise_count,
               type: Integer,
               readable: true,
               writeable: false

      property :completed_exercise_count,
               as: :complete_exercise_count,
               type: Integer,
               readable: true,
               writeable: false
    end

    class HomeworkTask < TaskBase
      property :actual_and_placeholder_exercise_count,
               as: :exercise_count,
               type: Integer,
               readable: true,
               writeable: false

      property :completed_exercise_count,
               as: :complete_exercise_count,
               type: Integer,
               readable: true,
               writeable: false

      property :correct_exercise_count,
               type: Integer,
               readable: true,
               writeable: false,
               if: -> (*) { past_due? && completed? }
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

    class Course < Roar::Decorator
      include Roar::JSON

      property :name,
               readable: true,
               writeable: false,
               type: String

      collection :teacher_names,
                 readable: true,
                 writeable: false,
                 type: String
    end

    # Actual attributes below

    collection :plans,
               readable: true,
               writeable: false,
               decorator: Plan

    collection :tasks,
               readable: true,
               writeable: false,
               skip_render: -> (object, options) {
                 !['reading','homework','external'].include?(object.task_type.to_s)
               },
               decorator: -> (task, *) {
                 case task.task_type.to_s
                 when 'reading'
                   ReadingTask
                 when 'homework'
                   HomeworkTask
                 else
                   TaskBase
                 end
               }

    property :role,
             readable: true,
             writeable: false,
             decorator: Role

    property :course,
             readable: true,
             writeable: false,
             decorator: Course


  end

end
