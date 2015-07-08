class AddUserAsCourseTeacher
  lev_routine express_output: :role

  uses_routine UserIsCourseTeacher
  uses_routine Role::CreateUserRole, translations: {outputs: {type: :verbatim}}
  uses_routine CourseMembership::AddTeacher

  protected

  def exec(user:, course:)
    result = run(UserIsCourseTeacher, user: user, course: course)
    fatal_error(code: :user_is_already_teacher_of_course, offending_inputs: [user, course]) \
      if result.outputs.user_is_course_teacher

    run(Role::CreateUserRole, user, :teacher)
    run(CourseMembership::AddTeacher, course: course, role: outputs.role)
  end
end
