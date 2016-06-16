class Tasks::GetRedirectUrl
  lev_routine

  uses_routine ChooseCourseRole, translations: { outputs: { type: :verbatim } }

  protected

  def exec(gid:, user:)
    task_plan = GlobalID::Locator.locate(gid)

    fatal_error(code: :plan_not_found) if task_plan.nil?
    fatal_error(code: :authentication_required) if user.is_anonymous?

    course = task_plan.owner

    run(:choose_course_role, user: user, course: course)

    case outputs.role.role_type
    when 'teacher'
      outputs[:uri] = "/courses/#{course.id}/t/#{task_plan.type.pluralize}/#{task_plan.id}"
    when 'student'
      task = task_plan.tasks.joins(:taskings).find_by(taskings: { role: outputs.role })

      fatal_error(code: :plan_not_published) if task.nil?
      fatal_error(code: :task_not_open) if !task.past_open?

      outputs[:uri] = "/courses/#{course.id}/tasks/#{task.id}"
    end
  end

end
