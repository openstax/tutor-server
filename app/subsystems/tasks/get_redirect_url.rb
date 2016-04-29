class Tasks::GetRedirectUrl
  lev_routine

  protected

  def exec(gid:, user:)
    task_plan = GlobalID::Locator.locate(gid)
    course = task_plan.owner
    role = get_role(user: user, course: course)
    if role.role_type == 'teacher'
      outputs[:uri] = edit_task_plan_page(course: course,
                                          task_plan: task_plan)
    elsif role.role_type == 'student'
      outputs[:uri] = task_page(course: course,
                                role: role,
                                task_plan: task_plan)
    end
  end

  def edit_task_plan_page(course:, task_plan:)
    "/courses/#{course.id}/t/#{task_plan.type.pluralize}/#{task_plan.id}"
  end

  def task_page(course:, role:, task_plan:)
    task = Tasks::GetTasks[roles: [role]].joins(:task).where(
      task: { tasks_task_plan_id: task_plan.id }).first
    "/courses/#{course.id}/tasks/#{task.id}"
  end

  def get_role(user:, course:)
    result = ChooseCourseRole.call(user: user, course: course)
    if result.errors.any?
      raise(SecurityTransgression, result.errors.map(&:message).to_sentence)
    end
    result.outputs.role
  end
end
