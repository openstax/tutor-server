class GetRoleCourseEvents
  lev_routine

  uses_routine GetCourseTaskPlans,
               as: :get_plans,
               translations: { outputs: { map: { items: :plans } } }
  uses_routine Tasks::GetTasks,
               as: :get_tasks

  protected

  def exec(course:, role:)
    if CourseMembership::IsCourseTeacher[course: course, roles: role]
      collect_teacher_events(course: course, role: role)
    elsif CourseMembership::IsCourseStudent[course: course, roles: role]
      collect_student_events(course: course, role: role)
    end
  end

  def collect_teacher_events(course:, role:)
    run(:get_plans, course: course)

    run(:get_tasks, roles: role)
    entity_task_ids = outputs["[:get_tasks, :tasks]"].collect{|entity_task| entity_task.id}
    outputs[:tasks] = Tasks::Models::Task.where{entity_task_id.in entity_task_ids}
  end

  def collect_student_events(course:, role:)
    run(:get_tasks, roles: role)
    entity_task_ids = outputs["[:get_tasks, :tasks]"].collect{|entity_task| entity_task.id}
    outputs[:tasks] = Tasks::Models::Task.where{entity_task_id.in entity_task_ids}
  end
end
