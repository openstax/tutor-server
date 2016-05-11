class Tasks::CourseTimeZoneChanged
  lev_routine

  uses_routine CourseMembership::GetCourseRoles, as: :get_course_roles
  uses_routine Tasks::GetTasks, as: :get_tasks

  protected

  def exec(course:, old_time_zone_name:, new_time_zone_name:)
    return if old_time_zone_name == new_time_zone_name

    @old_time_zone = ActiveSupport::TimeZone[old_time_zone_name]
    @new_time_zone = ActiveSupport::TimeZone[new_time_zone_name]

    # Update tasking plans; could just query tasking plans directly, but we also
    # want to lock task plans so that we don't get simultaneous updates from saving
    # or publishing plans.

    task_plans = Tasks::Models::TaskPlan.lock.where{owner == course}.includes(:tasking_plans)

    task_plans.each do |task_plan|
      task_plan.tasking_plans.each do |tasking_plan|
        tasking_plan.opens_at = change_time_zone(tasking_plan.opens_at)
        tasking_plan.due_at = change_time_zone(tasking_plan.due_at)
        tasking_plan.save

        transfer_errors_from tasking_plan, {type: :verbatim}, true
      end

      task_plan.touch # makes the lock effective (waiting transactions won't
                      # proceed with stale data)
    end

    # Update existing tasks in this course

    student_roles = run(:get_course_roles, course: course, types: :student).outputs.roles
    entity_tasks = run(:get_tasks, roles: student_roles).outputs.tasks
    tasks = Tasks::Models::Task.lock.where{entity_task_id.in entity_tasks.map(&:id)}

    tasks.find_each do |task|
      task.opens_at = change_time_zone(task.opens_at)
      task.due_at = change_time_zone(task.due_at)
      task.save

      transfer_errors_from task, {type: :verbatim}, true
    end
  end

  def change_time_zone(time)
    DateTimeUtilities.keep_time_change_zone(time, @old_time_zone, @new_time_zone)
  end
end
