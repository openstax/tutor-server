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
          raise StandardError, 'External assignment taskees must all be students'
        else
          taskees.collect.with_index do |taskee, i|
            build_event_task(task_plan: task_plan,
                             taskee: taskee,
                             student: students[i]).entity_task
          end
        end
      end

      private
      attr_reader :task_plan, :taskees

      def build_event_task(task_plan:, taskee:, student:)
        task = build_task(task_plan: task_plan)
        task.task_steps << Tasks::Models::TaskStep.new(task: task)
        task
      end

      def build_task(task_plan:)
        title = task_plan.title || 'Event'
        description = task_plan.description

        Tasks::BuildTask[task_plan: task_plan,
                         task_type: :event,
                         title: title,
                         description: description]
      end
    end
  end
end
