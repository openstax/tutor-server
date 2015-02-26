class Domain::AddUserAsCourseStudent
  lev_routine

  uses_routine Domain::UserIsCourseTeacher,
               translations: {type: :verbatim}

  uses_routine Domain::UserIsCourseStudent,
               translations: {type: :verbatim}

  uses_routine Role::CreateUserRole,
               translations: {type: :verbatim}

  uses_routine CourseMembership::AddStudent,
               translations: {type: :verbatim}

  protected

  def exec(user:, course:)
    result = run(Domain::UserIsCourseTeacher, user: user, course: course)
    fatal_error(code: :could_not_determine_if_user_is_course_teacher, offending_inputs: [user, course]) if result.errors.any?

    unless result.outputs.user_is_course_teacher
      result = run(Domain::UserIsCourseStudent, user: user, course: course)
      fatal_error(code: :could_not_determine_if_user_is_course_student, offending_inputs: [user, course]) if result.errors.any?
      fatal_error(code: :user_is_already_a_course_student, offending_inputs: [user, course]) if result.outputs.user_is_course_student
    end

    result = run(Role::CreateUserRole, user)
    fatal_error(code: :could_not_add_student_role, offending_inputs: [user, course]) if result.errors.any?
    role = result.outputs.role

    result = run(CourseMembership::AddStudent, course: course, role: role)
    fatal_error(code: :could_not_add_student, offending_inputs: [user, course]) if result.errors.any?

    outputs[:role] = role
  end
end
