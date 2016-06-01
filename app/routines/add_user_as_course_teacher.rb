class AddUserAsCourseTeacher
  lev_routine express_output: :role

  uses_routine UserIsCourseTeacher, as: :is_teacher
  uses_routine Role::CreateUserRole, translations: { outputs: { type: :verbatim } }
  uses_routine CourseMembership::AddTeacher, translations: { outputs: { type: :verbatim } }

  protected

  def exec(user:, course:)
    if run(:is_teacher, user: user, course: course).outputs.user_is_course_teacher
      fatal_error(code: :user_is_already_teacher_of_course,
                  message: 'You are already a teacher of this course.',
                  offending_inputs: [user, course])
    else
      run(Role::CreateUserRole, user, :teacher)
      run(CourseMembership::AddTeacher, course: course, role: outputs.role)
    end
  end
end
