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
    # Because we need to be able to have a deidentifier on taskees for external
    # assignments, we check to make sure that all taskee roles are students (only
    # model that currently has a deidentifier).  It is up to the caller to decide
    # if the taskees can be inactive students or not, so we will check against all
    # students, active and inactive.  This also helps us deal with legacy dropped
    # students where the students have `deleted_at` set but the related enrollments
    # do not (from before when we were acts_as_paranoid everywhere).

    role_ids = roles.map(&:id)
    role_students = CourseMembership::Models::Student.with_deleted
                                                     .where(entity_role_id: role_ids)
                                                     .index_by(&:entity_role_id)

    roles.map do |role|
      student = role_students[role.id]

      if student.nil?
        raise StandardError, "External assignment taskees must all be students, " \
                             "plan: #{task_plan.id}, bad role id: #{role.id}, all " \
                             "role ids: #{role_ids.inspect}"
      end

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
