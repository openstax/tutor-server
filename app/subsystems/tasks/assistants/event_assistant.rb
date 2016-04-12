module Tasks
  module Assistants
    class EventAssistant < Tasks::Assistants::GenericAssistant
      def self.schema
        '{
          "type": "object",
          "required": [],
          "properties": {},
          "additionalProperties": false
        }'
      end

      def build_tasks
        taskees.map do
          Tasks::BuildTask[task_plan: task_plan,
                           task_type: :event,
                           title: task_plan.title,
                           description: task_plan.description]
        end.map(&:entity_task)
      end

      private
      attr_reader :task_plan, :taskees
    end
  end
end
