class GetCourseTeachers
  lev_routine express_output: :teachers

  uses_routine CourseMembership::GetTeachers, translations: { outputs: { type: :verbatim } }

  protected

  def exec(course)
    teachers = run(CourseMembership::GetTeachers, course).outputs.teachers
    teachers = teachers.preload(role: { profile: :account })

    outputs.teachers = teachers.map do |teacher|
      {
        id: teacher.id.to_s,
        role_id: teacher.entity_role_id.to_s,
        deleted_at: teacher.deleted_at,
        first_name: teacher.first_name,
        last_name: teacher.last_name
      }
    end
  end
end
