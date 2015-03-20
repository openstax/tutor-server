class Domain::AddUserAsCourseStudent
  lev_routine

  uses_routine Domain::UserIsCourseTeacher
  uses_routine Domain::UserIsCourseStudent
  uses_routine Role::CreateUserRole, translations: {outputs: {type: :verbatim}}
  uses_routine CourseMembership::AddStudent

  protected

  def exec(user:, course:)
    result = run(Domain::UserIsCourseTeacher, user: user, course: course)
    unless result.outputs.user_is_course_teacher
      result = run(Domain::UserIsCourseStudent, user: user, course: course)
      fatal_error(code: :user_is_already_a_course_student, offending_inputs: [user, course]) \
        if result.outputs.user_is_course_student
    end

    run(Role::CreateUserRole, user, :student)
    run(CourseMembership::AddStudent, course: course, role: outputs.role)
  end
end
