class GetDashboard
  lev_routine

  uses_routine GetCourseTaskPlans,
               as: :get_plans
  uses_routine ::Tasks::GetTasks,
               as: :get_tasks
  uses_routine GetCourseProfile,
               as: :get_course_profile
  uses_routine GetCourseTeachers,
               as: :get_course_teachers

  protected

  def exec(course:, role:)
    role_type = get_role_type(course, role)

    raise SecurityTransgression if role_type.nil?

    load_tasks(role, role_type)
    load_plans(course) if :teacher == role_type
    load_course(course, role_type)
    load_role(role, role_type)
  end

  def get_role_type(course, role)
    if CourseMembership::IsCourseTeacher[course: course, roles: role]
      :teacher
    elsif CourseMembership::IsCourseStudent[course: course, roles: role]
      :student
    end
  end

  def load_tasks(role, role_type)
    run(:get_tasks, roles: role)
    entity_task_ids = outputs["[:get_tasks, :tasks]"].collect{|entity_task| entity_task.id}
    tasks = Tasks::Models::Task.where{entity_task_id.in entity_task_ids}
    tasks = tasks.where{ opens_at.lt Time.now } if :student == role_type
    outputs[:tasks] = tasks
  end

  def load_plans(course)
    out = run(:get_plans, course: course, include_trouble_flags: true).outputs
    outputs[:plans] = out[:plans].collect do |task_plan|
      {
        id: task_plan.id,
        title: task_plan.title,
        type: task_plan.type,
        is_publish_requested: task_plan.is_publish_requested?,
        published_at: task_plan.published_at,
        publish_last_requested_at: task_plan.publish_last_requested_at,
        publish_job_uuid: task_plan.publish_job_uuid,
        tasking_plans: task_plan.tasking_plans,
        is_trouble: out[:trouble_plan_ids].include?(task_plan.id)
      }
    end
  end

  def load_course(course, role_type)
    run(:get_course_profile, course: course)
    run(:get_course_teachers, course)

    outputs[:course] = {
      id: course.id,
      name: outputs["[:get_course_profile, :profile]"].name,
      teachers: outputs["[:get_course_teachers, :teachers]"]
    }
  end

  def load_role(role, role_type)
    outputs.role = {
      id: role.id,
      type: role_type.to_s
    }
  end

end
