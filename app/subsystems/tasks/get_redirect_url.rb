class Tasks::GetRedirectUrl
  lev_routine

  uses_routine ChooseCourseRole, translations: { outputs: { type: :verbatim } }

  protected

  def exec(gid:, user:)
    task_plan = GlobalID::Locator.locate(gid)
    course = task_plan.owner

    run(:choose_course_role, user: user, course: course)

    case outputs.role.role_type
    when 'teacher'
      outputs[:uri] = "/courses/#{course.id}/t/#{task_plan.type.pluralize}/#{task_plan.id}"
    when 'student'
      task = Tasks::GetTasks[roles: outputs.role].where(tasks_task_plan_id: task_plan.id).first

      fatal_error(code: :plan_not_published) if task.nil?
      fatal_error(code: :task_not_open) if !task.past_open?

      outputs[:uri] = "/courses/#{course.id}/tasks/#{task.id}"
    end
  end

end
