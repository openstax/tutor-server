class Tasks::Assistants::ExternalAssignmentAssistant

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

  def self.build_tasks(task_plan:, taskees:)
    url = task_plan.settings['external_url']
    taskees.collect do |taskee|
      build_external_task(task_plan: task_plan, taskee: taskee, url: url)
    end
  end

  protected
  def self.build_external_task(task_plan:, taskee:, url:)
    task = build_task(task_plan: task_plan)
    step = Tasks::Models::TaskStep.new(task: task)
    Tasks::Models::TaskedExternalUrl.new(task_step: step, url: url)
    task.task_steps << step
    task
  end

  def self.build_task(task_plan:)
    title = task_plan.title || 'External Assignment'
    description = task_plan.description

    Tasks::BuildTask[
      task_plan: task_plan,
      task_type: :external,
      title: title,
      description: description
    ]
  end
end
