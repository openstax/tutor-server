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
    students = @taskees.map(&:student).compact

    raise StandardError, 'External assignment taskees must all be students'\
      if students.length != @taskees.length

    @taskees.map.with_index do |taskee, i|
      build_external_task(task_plan: @task_plan,
                          taskee: taskee,
                          student: students[i])
    end
  end

  protected

  def build_external_task(task_plan:, taskee:, student:)
    task = build_task(task_plan: task_plan)
    step = Tasks::Models::TaskStep.new(task: task)
    tasked_external_url(task_step: step, taskee: taskee, student: student,
                        url: task_plan.settings['external_url'])
    task.add_step(step)
    task
  end

  def build_task(task_plan:)
    title = task_plan.title || 'External Assignment'
    description = task_plan.description

    Tasks::BuildTask[
      task_plan: task_plan,
      task_type: :external,
      title: title,
      description: description
    ]
  end

  def tasked_external_url(task_step:, taskee:, student:, url:)
    {
      deidentifier: student.try(:deidentifier)
    }.each do |key, value|
      url = url.gsub("{{#{key}}}", value)
    end
    Tasks::Models::TaskedExternalUrl.new(task_step: task_step, url: url)
  end
end
