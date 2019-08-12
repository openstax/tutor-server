class UserIsCourseTeacher
  lev_routine express_output: :is_course_teacher

  uses_routine CourseMembership::IsCourseTeacher, translations: { outputs: { type: :verbatim } }

  protected

  def exec(user:, course:, include_deleted_teachers: false)
    outputs.roles = user.roles

    run(
      CourseMembership::IsCourseTeacher,
      roles: outputs.roles,
      course: course,
      include_deleted_teachers: include_deleted_teachers
    )
  end
end
