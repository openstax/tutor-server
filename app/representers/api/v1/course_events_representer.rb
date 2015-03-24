module Api::V1

  class CourseEventsRepresenter < OpenStax::Api::V1::AbstractSearchRepresenter

    class CommonElements < Roar::Decorator
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

    class PlanElements < CommonElements

      property :trouble,
               type: :boolean,
               readable: true,
               getter: lambda{|*| rand(0..1)==0 }
        # ^^^^^ REPLACE with real value once spec for calculating it's available

      property :type,
               type: String,
               readable: true
    end

    class TaskElements < CommonElements

      property :task_type, as: :type,
               type: String,
               readable: true

      property :completed?, as: :complete,
               type: :boolean,
               readable: true

    end

    collection :plans, readable: true, decorator: PlanElements

    collection :tasks, readable: true, decorator: TaskElements

  end
end
