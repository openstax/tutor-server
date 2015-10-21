class CourseMembership::CreateEnrollmentChange
  lev_routine express_output: :enrollment_change

  uses_routine Role::GetUserRoles, as: :get_roles
  uses_routine CourseMembership::ApproveEnrollmentChange, as: :approve

  def exec(user:, period:, requires_enrollee_approval: true)
    user_student_role_ids = run(:get_roles, user, 'student').outputs.roles.map(&:id)
    user_course_students = CourseMembership::Models::Student.where(
      entity_course_id: period.course.id,  entity_role_id: user_student_role_ids
    ).to_a

    # This code does NOT support users with multiple "students" (teachers) trying to change periods
    fatal_error(code: :multiple_roles,
                message: 'Users with multiple roles in a course cannot use self-enrollment') \
      if user_course_students.size > 1

    student = user_course_students.first

    if student.nil?
      enrollment = nil
    else
      fatal_error(code: :dropped_student,
                  message: 'You cannot re-enroll in a course from which you were dropped') \
        unless student.active?

      enrollment = student.latest_enrollment
    end

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
