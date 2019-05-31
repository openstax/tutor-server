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
    all_tasks = run(:get_tasks, roles: role, start_at_ntz: start_at_ntz, end_at_ntz: end_at_ntz)
                  .outputs.tasks.preload(:time_zone, :task_plan, :task_steps).to_a

    tasks = all_tasks.reject(&:hidden?)

    tasks = tasks.select do |task|
      task.past_open? current_time: current_time
    end unless role.teacher?

    ready_task_ids = Tasks::IsReady[tasks: tasks]
    ready_tasks = tasks.select { |task| ready_task_ids.include? task.id }

    outputs.tasks = ready_tasks
    outputs.all_tasks_are_ready = ready_tasks == tasks

    return if role.teacher?

    period_id = role.course_member.course_membership_period_id
    outputs.all_tasks_are_ready = outputs.all_tasks_are_ready && Tasks::Models::TaskPlan
      .joins(:tasking_plans)
      .preload(:tasking_plans)
      .where(
        tasking_plans: { target_id: period_id, target_type: 'CourseMembership::Models::Period' }
      )
      .where.not(first_published_at: nil)
      .count <= all_tasks.size
  end
end
