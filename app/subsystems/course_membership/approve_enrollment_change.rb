class CourseMembership::ApproveEnrollmentChange
  lev_routine express_output: :enrollment_change

  uses_routine AddUserAsPeriodStudent, as: :add_student
  uses_routine CourseMembership::AddEnrollment, as: :add_enrollment

  def exec(enrollment_change:, approved_by:)
    fatal_error(code: :already_approved,
                message: 'The given enrollment change request has already been approved') \
      if enrollment_change.approved?
    fatal_error(code: :already_rejected,
                message: 'The given enrollment change request has already been rejected') \
      if enrollment_change.rejected?

    enrollment_change_model = enrollment_change.to_model

    enrollment = enrollment_change_model.enrollment
    if enrollment.nil?
      # New student
      run(:add_student, user: enrollment_change.user, period: enrollment_change.to_period)
    else
      # Existing student
      student = enrollment.student
      run(:add_enrollment, student: student, period: enrollment_change.to_period)
    end

    enrollment_change_model.approve_by(approved_by).save!

    # Mark other pending EnrollmentChange records as rejected
    CourseMembership::Models::EnrollmentChange.where(
      user_profile_id: enrollment_change_model.user_profile_id,
      status: CourseMembership::Models::EnrollmentChange.statuses[:pending],
      course_membership_period_id: enrollment_change_model.period.course.periods.map(&:id)
    ).update_all(status: CourseMembership::Models::EnrollmentChange.statuses[:rejected])

    outputs[:enrollment_change] = enrollment_change
  end
end
