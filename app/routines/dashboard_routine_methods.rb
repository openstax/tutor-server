module DashboardRoutineMethods
  BL_TIMEOUT = 30.minutes

  def self.included(base)
    base.lev_routine

    base.uses_routine ::Tasks::GetTasks, as: :get_tasks
    base.uses_routine GetCourseTeachers, as: :get_course_teachers
    base.uses_routine CourseMembership::IsCourseTeacher
    base.uses_routine CourseMembership::IsCourseStudent
  end

  protected

  def get_role_type(course, role)
    if CourseMembership::IsCourseTeacher[course: course, roles: role]
      :teacher
    elsif CourseMembership::IsCourseStudent[course: course, roles: role]
      :student
    else
      :none
    end
  end

  def load_role(role, role_type)
    outputs.role = { id: role.id, type: role_type.to_s }
  end

  def load_course(course, role_type)
    teachers = run(:get_course_teachers, course).outputs.teachers

    outputs.course = { id: course.id, name: course.name, teachers: teachers }
  end

  def load_tasks(role, role_type, start_at_ntz = nil, end_at_ntz = nil, current_time = Time.current)
    all_tasks = run(:get_tasks, roles: role, start_at_ntz: start_at_ntz, end_at_ntz: end_at_ntz)
                  .outputs.tasks.preload(:time_zone, :task_plan, :task_steps).to_a

    tasks = all_tasks.reject(&:hidden?)

    tasks = tasks.select do |task|
      task.past_open? current_time: current_time
    end if role_type != :teacher

    bl_expired = BL_TIMEOUT.ago
    ready_task_ids = Tasks::IsReady[tasks: tasks]
    ready_tasks = tasks.select { |task|
      ready_task_ids.include?(task.id)
    }
    outputs.tasks = tasks.select { |task|
      task.created_at < bl_expired || ready_task_ids.include?(task.id)
    }
    outputs.all_tasks_are_ready = ready_tasks == tasks && (
      role_type != :student || Tasks::Models::TaskPlan
                                 .joins(:tasking_plans)
                                 .preload(:tasking_plans)
                                 .where(tasking_plans: {
                                   target_id: role.student.course_membership_period_id,
                                   target_type: 'CourseMembership::Models::Period'
                                 })
                                 .where { first_published_at != nil }
                                 .count <= all_tasks.size
    )
    if ready_tasks != outputs.tasks
      err = "TASK READINESS TIMED OUT! student role: #{role.id}"
      Rails.logger.warn(err)
      Raven.capture_message(err)
    end
  end
end
