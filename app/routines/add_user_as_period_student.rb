class AddUserAsPeriodStudent
  lev_routine express_output: :role

  uses_routine UserIsCourseTeacher
  uses_routine UserIsCourseStudent
  uses_routine Role::CreateUserRole, translations: { outputs: { type: :verbatim } }
  uses_routine CourseMembership::AddStudent, translations: { outputs: { type: :verbatim } }

  protected

  def exec(user:, period:, student_identifier: nil, assign_published_period_tasks: true)
    student_identifier = nil if student_identifier.blank?
    course = period.course
    result = run(UserIsCourseTeacher, user: user, course: course)

    unless result.outputs.user_is_course_teacher
      user_test = run(UserIsCourseStudent, user: user, course: course,
                      include_dropped: true, include_archived: true).outputs

      fatal_error(code: :user_is_an_inactive_student, offending_inputs: [user, course]) \
                 if user_test.is_dropped || user_test.is_archived

      fatal_error(code: :user_is_already_a_course_student, offending_inputs: [user, course]) \
                 if user_test.user_is_course_student
    end

    run(Role::CreateUserRole, user, :student)
    run(CourseMembership::AddStudent, period: period, role: outputs.role,
                                      student_identifier: student_identifier,
                                      assign_published_period_tasks: assign_published_period_tasks)
  end

end
