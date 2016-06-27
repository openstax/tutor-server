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
        taskees.map{ build_task(type: :event, default_title: 'Event') }
      end

      private

      attr_reader :task_plan, :taskees
    end
  end
end
