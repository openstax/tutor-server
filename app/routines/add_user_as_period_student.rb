class AddUserAsPeriodStudent
  lev_routine express_output: :role

  uses_routine UserIsCourseTeacher
  uses_routine UserIsCourseStudent
  uses_routine Role::CreateUserRole,
    translations: { outputs: { type: :verbatim } }
  uses_routine CourseMembership::AddStudent,
    translations: { outputs: { type: :verbatim } }

  protected

  def exec(user:, period:)
    course = period.course
    result = run(UserIsCourseTeacher, user: user, course: course)

    unless result.outputs.user_is_course_teacher
      result = run(UserIsCourseStudent, user: user, course: course)

      if result.outputs.user_is_course_student
        fatal_error(code: :user_is_already_a_course_student,
                    offending_inputs: [user, course])
      end
    end

    run(Role::CreateUserRole, user, :student)
    run(CourseMembership::AddStudent, period: period, role: outputs.role)
  end
end
