class AddUserAsPeriodStudent

  lev_routine express_output: :role

  uses_routine UserIsCourseTeacher
  uses_routine UserIsCourseStudent
  uses_routine Role::CreateUserRole, translations: { outputs: { type: :verbatim } }
  uses_routine CourseMembership::AddStudent, translations: { outputs: { type: :verbatim } }

  protected

  def exec(user:, period:, student_identifier: nil,
           reassign_published_period_task_plans: true, send_to_biglearn: true)
    student_identifier = nil if student_identifier.blank?
    course = period.course
    result = run(UserIsCourseTeacher, user: user, course: course)

    unless result.outputs.user_is_course_teacher
      result = run(UserIsCourseStudent, user: user, course: course, include_dropped_students: true)

      fatal_error(code: :user_is_already_a_course_student, offending_inputs: [user, course]) \
        if result.outputs.user_is_course_student

      fatal_error(code: :period_is_archived, offending_inputs: [user, course]) \
        if period.archived?
    end

    run(Role::CreateUserRole, user, :student)
    run(
      CourseMembership::AddStudent,
      period: period,
      role: outputs.role,
      student_identifier: student_identifier,
      reassign_published_period_task_plans: reassign_published_period_task_plans,
      send_to_biglearn: send_to_biglearn
    )
  end

end
