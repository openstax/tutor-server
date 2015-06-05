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
               readable: true,
               writeable: false,
               getter: lambda{|*| rand(0..1)==0 },
               schema_info: { type: 'boolean' }
        # ^^^^^ REPLACE with real value once spec for calculating it's available

      property :type,
               type: String,
               readable: true,
               writeable: false

      collection :periods,
                 readable: true,
                 writeable: false,
                 decorator: Api::V1::PeriodRepresenter,
                 getter: ->(*) { tasking_plans.collect{ |tt| tt.target } }

    end

    class TaskBase < Base

      property :opens_at,
               type: DateTime,
               readable: true,
               writeable: false

      property :due_at,
               type: DateTime,
               readable: true,
               writeable: false

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
                 !['reading','homework'].include?(object.task_type.to_s)
               },
               decorator: -> (task, *) {
                 case task.task_type.to_s
                 when 'reading'
                   ReadingTask
                 when 'homework'
                   HomeworkTask
                 else
                   raise "Unknown task type: #{task.task_type}"
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
