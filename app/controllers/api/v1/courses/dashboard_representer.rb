module Api::V1::Courses

  class DashboardRepresenter < ::Roar::Decorator

    include ::Roar::JSON

    class Base < Roar::Decorator
      include Roar::JSON

      property :id,
               type: Integer,
               readable: true

      property :title,
               type: String,
               readable: true

      property :opens_at,
               type: DateTime,
               readable: true

      property :due_at,
               type: DateTime,
               readable: true

    end

    class Plan < Base

      property :trouble,
               type: :boolean,
               readable: true,
               getter: lambda{|*| rand(0..1)==0 }
        # ^^^^^ REPLACE with real value once spec for calculating it's available

      property :type,
               type: String,
               readable: true
    end

    class TaskBase < Base

      property :task_type,
               as: :type,
               type: String,
               readable: true

      property :'completed?',
               as: :complete,
               type: :boolean,
               readable: true
    end

    class ReadingTask < TaskBase
      property :exercise_count,
               type: Integer,
               readable: true

      property :complete_exercise_count,
               type: Integer,
               readable: true
    end

    class HomeworkTask < TaskBase
      property :exercise_count,
               type: Integer,
               readable: true

      property :complete_exercise_count,
               type: Integer,
               readable: true

      property :correct_exercise_count,
               type: Integer,
               readable: true,
               if: -> (*) { past_due? && completed? }
    end

    class Role < Roar::Decorator
      include Roar::JSON

      property :id,
               readable: true,
               type: Integer

      property :type,
               readable: true,
               type: String
    end

    class Course < Roar::Decorator
      include Roar::JSON

      property :name,
               readable: true,
               type: String

      collection :teacher_names,
                 readable: true,
                 type: String
    end

    # Actual attributes below

    collection :plans,
               readable: true,
               decorator: Plan

    collection :tasks,
               readable: true,
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
             decorator: Role

    property :course,
             readable: true,
             decorator: Course


  end

end
