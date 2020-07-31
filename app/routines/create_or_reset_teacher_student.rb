class CreateOrResetTeacherStudent
  lev_routine express_output: :role

  uses_routine Role::CreateUserRole, translations: { outputs: { type: :verbatim } }
  uses_routine CourseMembership::AddTeacherStudent, translations: { outputs: { type: :verbatim } }

  protected

  def exec(user:, period:, reassign_published_period_task_plans: true)
    teacher_student = CourseMembership::Models::TeacherStudent
      .joins(:role)
      .find_by(course_membership_period_id: period.id, role: { user_profile_id: user.id })

    teacher_student.destroy unless teacher_student.nil?

    run(Role::CreateUserRole, user, :teacher_student)
    run(
      CourseMembership::AddTeacherStudent,
      period: period,
      role: outputs.role,
      reassign_published_period_task_plans: reassign_published_period_task_plans
    )
  end
end
