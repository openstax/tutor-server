class AddUserAsPeriodStudent
  lev_routine uses: [:user_is_course_teacher, :user_is_course_student],
              outputs: {
                _verbatim: [Role::CreateUserRole,
                            CourseMembership::AddStudent]
              }

  protected
  def exec(user:, period:, student_identifier: nil)
    course = period.course

    unless run(:user_is_course_teacher, user: user, course: course)
      if run(:user_is_course_student, user: user, course: course)
        fatal_error(code: :user_is_already_a_course_student,
                    offending_inputs: [user, course])
      end
    end

    run(:role_create_user_role, user, :student)
    run(:course_membership_add_student, period: period, role: result.role,
                                        student_identifier: student_identifier)
  end
end
