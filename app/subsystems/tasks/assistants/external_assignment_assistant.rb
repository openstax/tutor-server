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
    role_ids = roles.map(&:id)
    role_students = CourseMembership::Models::Student.where(entity_role_id: role_ids)
                                                     .index_by(&:entity_role_id)

    roles.map do |role|
      student = role_students[role.id]
      raise StandardError, 'External assignment taskees must all be students' if student.nil?

      build_external_task(role: role, student: student)
    end
  end

  protected

  def build_external_task(role:, student:)
    task = build_task(type: :external, default_title: 'External Assignment')
    step = Tasks::Models::TaskStep.new(task: task)
    step.tasked = tasked_external_url(
      task_step: step, student: student, url: task_plan.settings['external_url']
    )
    task.add_step(step)
    task
  end

  def tasked_external_url(task_step:, student:, url:)
    url = url.gsub('{{deidentifier}}', student.try(:deidentifier))
    Tasks::Models::TaskedExternalUrl.new(task_step: task_step, url: url)
  end
end
