class Tasks::GetRedirectUrl
  lev_routine

  uses_routine ChooseCourseRole, translations: { outputs: { type: :verbatim } }

  protected

  def exec(gid:, user:, role:)
    task_plan = GlobalID::Locator.locate(gid)

    fatal_error(code: :plan_not_found) if task_plan.nil?
    fatal_error(code: :authentication_required) if user.is_anonymous?

    course = task_plan.owner

    run(:choose_course_role, user: user, course: course, role: role)

    case outputs.role.role_type
    when 'teacher'
      outputs[:uri] = UrlGenerator.teacher_task_plan_review(
        course_id: course.id,
        due_at: task_plan.tasking_plans.first.due_at_ntz,
        task_plan_id:task_plan.id
      )
    when 'student'
      task = task_plan.tasks.joins(:taskings).find_by(taskings: { role: outputs.role })

      fatal_error(code: :plan_not_published) if task.nil?
      fatal_error(code: :task_not_open) if !task.past_open?

      outputs[:uri] = UrlGenerator.student_task(course_id: course.id, task_id: task.id)
    end
  end

end
