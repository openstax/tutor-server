class GetDashboard
  lev_routine

  uses_routine GetCourseTaskPlans,
               as: :get_plans
  uses_routine ::Tasks::GetTasks,
               as: :get_tasks
  uses_routine GetCourseTeachers,
               as: :get_course_teachers
  uses_routine CourseMembership::IsCourseTeacher
  uses_routine CourseMembership::IsCourseStudent

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
    entity_tasks = run(:get_tasks, roles: role).outputs.tasks
    entity_tasks = entity_tasks.joins(:task).preload(:task)
    entity_tasks = entity_tasks.where{ task.opens_at < Time.now } if :student == role_type
    tasks = entity_tasks.collect{ |entity_task| entity_task.task }
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
    teachers = run(:get_course_teachers, course).outputs.teachers

    outputs[:course] = {
      id: course.id,
      name: course.name,
      teachers: teachers
    }
  end

  def load_role(role, role_type)
    outputs.role = {
      id: role.id,
      type: role_type.to_s
    }
  end

end
