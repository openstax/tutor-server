module Tasks
  module Assistants
    class EventAssistant
      def self.schema
        '{
          "type": "object",
          "required": [],
          "properties": {},
          "additionalProperties": false
        }'
      end

      def initialize(task_plan:, taskees:)
        @task_plan = task_plan
        @taskees = taskees
      end

      def build_tasks
        students = taskees.flat_map(&:student).compact

        if students.length != taskees.length
          raise StandardError, 'Event assignment taskees must all be students'
        else
          taskees.map do
            Tasks::BuildTask[task_plan: task_plan,
                             task_type: :event,
                             title: task_plan.title || 'Event',
                             description: task_plan.description]
          end
        end
      end

      private
      attr_reader :task_plan, :taskees
    end
  end
end
