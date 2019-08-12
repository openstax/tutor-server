class Tasks::GetRedirectUrl
  lev_routine

  uses_routine UserIsCourseTeacher, translations: { outputs: { type: :verbatim } }
  uses_routine UserIsCourseStudent, translations: { outputs: { type: :verbatim } }

  protected

  def exec(gid:, user:)
    task_plan = GlobalID::Locator.locate(gid)

    fatal_error(code: :plan_not_found) if task_plan.nil?
    fatal_error(code: :authentication_required) if user.is_anonymous?

    course = task_plan.owner

    run(:user_is_course_teacher, user: user, course: course)

    if outputs.is_course_teacher
      outputs.uri = UrlGenerator.teacher_task_plan_review(
        course_id: course.id,
        due_at: task_plan.tasking_plans.first.due_at_ntz,
        task_plan_id:task_plan.id
      )
    else
      run(:user_is_course_student, user: user, course: course)

      fatal_error(code: :user_not_in_course_with_required_role) \
        unless outputs.is_course_student

      task = task_plan.tasks.joins(:taskings).find_by(taskings: { role: outputs.student.role })

      fatal_error(code: :plan_not_published) if task.nil?
      fatal_error(code: :task_not_open) if !task.past_open?

      outputs.uri = UrlGenerator.student_task(course_id: course.id, task_id: task.id)
    end
  end

end
