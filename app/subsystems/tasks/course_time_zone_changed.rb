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

      transfer_errors_from tp, {type: :verbatim}, true
    end

    # Update existing tasks in this course

    student_roles = run(:get_course_roles, course: course, types: :student).outputs.roles
    entity_tasks = run(:get_tasks, roles: student_roles).outputs.tasks
    tasks = Tasks::Models::Task.where{entity_task_id.in entity_tasks.map(&:id)}

    tasks.each do |task|
      task.opens_at = change_time_zone(task.opens_at, old_time_zone, new_time_zone)
      task.due_at = change_time_zone(task.due_at, old_time_zone, new_time_zone)
      task.save

      transfer_errors_from task, {type: :verbatim}, true
    end
  end

  def change_time_zone(time, old_timezone, new_timezone)
    DateTimeUtilities.keep_time_change_zone(time, old_timezone, new_timezone)
  end
end
