class GetDashboard
  lev_routine

  uses_routine GetCourseTaskPlans,
               as: :get_plans,
               translations: { outputs: { map: { items: :plans } } }
  uses_routine ::Tasks::GetTasks,
               as: :get_tasks
  uses_routine GetCourseProfile,
               as: :get_course_profile
  uses_routine GetTeacherNames,
               as: :get_teacher_names

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
    run(:get_plans, course: course)
    outputs[:trouble_plan_ids] = Set.new Tasks::Models::TaskPlan.joins(:tasks).group(:id).having{
      (sum(tasks.completed_exercise_steps_count) > sum(tasks.exercise_steps_count)/4) & \
      (sum(tasks.correct_exercise_steps_count) < sum(tasks.completed_exercise_steps_count)/2)
    }.pluck(:id)
  end

  def load_course(course, role_type)
    run(:get_course_profile, course: course)
    run(:get_teacher_names, course.id)

    outputs[:course] = {
      id: course.id,
      name: outputs["[:get_course_profile, :profile]"].name,
      teacher_names: outputs["[:get_teacher_names, :teacher_names]"]
    }
  end

  def load_role(role, role_type)
    outputs.role = {
      id: role.id,
      type: role_type.to_s
    }
  end

end
