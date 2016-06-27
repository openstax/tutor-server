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
    role_ids = taskees.map(&:id)
    taskee_students = CourseMembership::Models::Student.where(entity_role_id: role_ids)
                                                       .index_by(&:entity_role_id)

    taskees.map do |taskee|
      student = taskee_students[taskee.id]
      raise StandardError, 'External assignment taskees must all be students' if student.nil?

      build_external_task(taskee: taskee, student: student)
    end
  end

  protected

  def build_external_task(taskee:, student:)
    task = build_task(type: :external, default_title: 'External Assignment')
    step = Tasks::Models::TaskStep.new(task: task)
    tasked_external_url(task_step: step, taskee: taskee, student: student,
                        url: task_plan.settings['external_url'])
    task.add_step(step)
    task
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
