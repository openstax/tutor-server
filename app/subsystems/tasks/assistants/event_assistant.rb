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
          build_task(type: :event, default_title: 'Event', time_zone: tasking_plan.time_zone)
        end
      end
    end
  end
end
