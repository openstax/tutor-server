module DashboardRoutineMethods
  def self.included(base)
    base.lev_routine

    base.uses_routine ::Tasks::GetTasks, as: :get_tasks
    base.uses_routine GetCourseTeachers, as: :get_course_teachers
    base.uses_routine CourseMembership::IsCourseTeacher
    base.uses_routine CourseMembership::IsCourseStudent
  end

  protected

  def load_role(role)
    outputs.role = { id: role.id, type: role.role_type.to_s }
  end

  def load_course(course)
    teachers = run(:get_course_teachers, course).outputs.teachers

    outputs.course = { id: course.id, name: course.name, teachers: teachers }
  end

  def load_tasks(role, start_at_ntz = nil, end_at_ntz = nil, current_time = Time.current)
    all_tasks = run(
      :get_tasks, roles: role, start_at_ntz: start_at_ntz, end_at_ntz: end_at_ntz
    ).outputs.tasks.preload(:course, :task_plan, :task_steps, taskings: { role: :extensions }).to_a

    visible_tasks = all_tasks.reject(&:hidden?)

    outputs.tasks = visible_tasks
    outputs.tasks = outputs.tasks.select { |task| task.past_open? current_time: current_time } \
      if role.student?

    # All task plans are ready
    outputs.all_tasks_are_ready = if role.teacher?
      # Teachers don't get tasks for course task_plans
      true
    else
      # Require that all task_plans have been distributed for non-teachers (including ghosts)
      # This code assumes all TaskPlans target periods (not courses and not directly students)
      all_task_plan_ids = Tasks::Models::TaskPlan
        .tasked_to_period_id(role.course_member.course_membership_period_id)
        .published
        .non_withdrawn
        .pluck(:id)

      ready_task_plan_ids = visible_tasks.map(&:tasks_task_plan_id)

      (all_task_plan_ids - ready_task_plan_ids).empty?
    end
  end
end
