class AddUserAsCourseTeacher
  lev_routine outputs: { role: { name: Role::CreateUserRole, as: :create_role } },
              uses: [{ name: UserIsCourseTeacher, as: :is_teacher },
                      { name: CourseMembership::AddTeacher, as: :add_teacher }]

  protected
  def exec(user:, course:)
    if run(:is_teacher, user: user, course: course)
      fatal_error(code: :user_is_already_teacher_of_course,
                  message: 'You are already a teacher of this course.',
                  offending_inputs: [user, course])
    else
      run(:create_role, user, :teacher)
      run(:add_teacher, course: course, role: result.role)
    end
  end
end
