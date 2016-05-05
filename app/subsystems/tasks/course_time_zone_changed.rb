class Tasks::CourseTimeZoneChanged
  lev_routine

  uses_routine CourseMembership::GetCourseRoles, as: :get_course_roles
  uses_routine Tasks::GetTasks, as: :get_tasks

  protected

  def exec(course:, old_time_zone_name:, new_time_zone_name:)
    return if old_time_zone_name == new_time_zone_name

    # TODO fail if plans currently publishing?  Could maybe do in the loop

    old_time_zone = ActiveSupport::TimeZone[old_time_zone_name]
    new_time_zone = ActiveSupport::TimeZone[new_time_zone_name]

    # Update task plans

    Tasks::Models::TaskingPlan.joins{task_plan}.where{task_plan.owner == course}.find_each do |tp|
      tp.opens_at = change_time_zone(tp.opens_at, old_time_zone, new_time_zone)
      tp.due_at = change_time_zone(tp.due_at, old_time_zone, new_time_zone)
      tp.save
    end

    # Update existing tasks in this course, including those from plans and
    # practice widgets, excluding concept coach tasks (which don't have timing)

    student_roles = run(:get_course_roles, course: course, types: :student).outputs.roles
    tasks = run(:get_tasks, roles: student_roles).outputs.tasks
    non_cc_tasks = Tasks::Models::Task.where{entity_task_id.in tasks.map(&:id)}

    non_cc_tasks.each do |task|
      task.opens_at = change_time_zone(task.opens_at, old_time_zone, new_time_zone)
      task.due_at = change_time_zone(task.due_at, old_time_zone, new_time_zone)
      task.save
    end

    # TODO quasi-unrelated: verify :concept_coach task_type not used
  end

  def change_time_zone(time, old_timezone, new_timezone)
    return nil if time.nil?
    old_time = time.in_time_zone(old_timezone)
    new_time = time.in_time_zone(new_timezone)
    old_time.to_datetime.change(offset: new_time.formatted_offset)
  end
end
