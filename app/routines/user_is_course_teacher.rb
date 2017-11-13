class UserIsCourseTeacher
  lev_routine

  uses_routine Role::GetUserRoles, translations: {outputs: {type: :verbatim}}
  uses_routine CourseMembership::IsCourseTeacher,
               translations: {
                 outputs: {
                   map: {
                     is_course_teacher: :user_is_course_teacher
                   }
                 }
               }

  protected

  def exec(user:, course:, include_deleted_teachers: false)
    run(Role::GetUserRoles, user)
    run(
      CourseMembership::IsCourseTeacher,
      roles: outputs.roles,
      course: course,
      include_deleted_teachers: include_deleted_teachers
    )
  end
end
