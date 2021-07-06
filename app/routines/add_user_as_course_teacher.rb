class AddUserAsCourseTeacher
  lev_routine express_output: :role

  uses_routine UserIsCourseTeacher, as: :is_teacher
  uses_routine Role::CreateUserRole, translations: { outputs: { type: :verbatim } }
  uses_routine CourseMembership::AddTeacher, translations: { outputs: { type: :verbatim } }

  protected

  def exec(user:, course:)
    outs = run(:is_teacher, user: user, course: course, include_deleted_teachers: true).outputs
    if outs.is_course_teacher
      teachers = outs.teachers
      if teachers.any? { |teacher| !teacher.deleted? }
        fatal_error(code: :user_is_already_a_course_teacher,
                    message: 'You are already a teacher of this course.',
                    offending_inputs: [user, course])
      else
        outputs.teacher = teachers.sort_by(&:created_at).last
        outputs.role = outputs.teacher.role
        outputs.teacher.restore
        transfer_errors_from outputs.teacher, { type: :verbatim }, true
      end
    else
      run(Role::CreateUserRole, user, :teacher)
      run(CourseMembership::AddTeacher, course: course, role: outputs.role)
    end
  end
end
