class Tasks::Assistants::ExternalAssignmentAssistant < Tasks::Assistants::GenericAssistant

  def self.schema
    '{
      "type": "object",
      "required": [
        "external_url"
      ],
      "properties": {
        "external_url": {
          "type": "string"
        }
      },
      "additionalProperties": false
    }'
  end

  def build_tasks
    individualized_tasking_plans.map do |tasking_plan|
      build_external_task(individualized_tasking_plan: tasking_plan, role: tasking_plan.target)
    end
  end

  protected

  def build_external_task(individualized_tasking_plan:, role:)
    task = build_task(type: :external,
                      default_title: 'External Assignment',
                      individualized_tasking_plan: individualized_tasking_plan)
    step = Tasks::Models::TaskStep.new(task: task, group_type: :fixed_group, is_core: true)
    step.tasked = tasked_external_url(
      task_step: step, role: role, url: task_plan.settings['external_url']
    )
    task.task_steps << step
    task
  end

  def tasked_external_url(task_step:, role:, url:)
    url = url.gsub('{{research_identifier}}', role.research_identifier)
    Tasks::Models::TaskedExternalUrl.new(task_step: task_step, url: url)
  end
end
