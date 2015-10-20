class CourseMembership::CreateEnrollmentChange
  lev_routine express_output: :enrollment_change

  uses_routine Role::GetUserRoles, as: :get_roles
  uses_routine CourseMembership::ApproveEnrollmentChange, as: :approve

  def exec(user:, period:, requires_enrollee_approval: true)
    role_ids = run(:get_roles, user, 'student').outputs.roles.collect(&:id)

    enrollments = CourseMembership::Models::Enrollment
                    .joins(:student)
                    .preload(:student)
                    .where(course_membership_period_id: period.id,
                           student: {entity_role_id: role_ids})
                    .to_a

    # This code does NOT support users with multiple roles (teachers) trying to change periods
    fatal_error(code: :multiple_roles,
                message: 'Users with multiple roles in a course cannot use self-enrollment') \
      if enrollments.size > 1

    enrollment = enrollments.first

    fatal_error(code: :dropped_student,
                message: 'You cannot re-enroll in a course from which you were dropped') \
      if !enrollment.nil? && !enrollment.student.active?

    enrollment_change = CourseMembership::Models::EnrollmentChange.create(
      user_profile_id: user.id, enrollment: enrollment, period: period.to_model,
      requires_enrollee_approval: requires_enrollee_approval
    )
    transfer_errors_from(enrollment_change, {type: :verbatim}, true)

    run(:approve, enrollment_change: enrollment_change, approved_by: user) \
      unless requires_enrollee_approval

    outputs[:enrollment_change] = enrollment_change
  end
end
