class GetRoleCourseEvents
  lev_routine

  uses_routine GetCourseTaskPlans,
               as: :get_plans,
               translations: { outputs: { map: { items: :plans } } }
  uses_routine Tasks::GetTasks,
               as: :get_tasks,
               translations: { outputs: { type: :verbatim } }

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
  end

  def collect_student_events(course:, role:)
    run(:get_tasks, roles: role)
  end
end
