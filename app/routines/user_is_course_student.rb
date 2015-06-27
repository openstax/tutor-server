class UserIsCourseStudent
  lev_routine

  uses_routine Role::GetUserRoles, translations: {outputs: {type: :verbatim}}
  uses_routine CourseMembership::IsCourseStudent,
               translations: {
                outputs: {
                  map: {
                    is_course_student: :user_is_course_student
                    }
                  }
                }

  protected

  def exec(user:, course:)
    run(Role::GetUserRoles, user)
    run(CourseMembership::IsCourseStudent, roles: outputs.roles, course: course)
  end
end
