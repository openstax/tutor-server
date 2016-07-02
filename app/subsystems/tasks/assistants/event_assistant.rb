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
        individualized_tasking_plans.map do |tasking_plan|
          build_task(type: :event, default_title: 'Event',
                     individualized_tasking_plan: tasking_plan)
        end
      end
    end
  end
end
