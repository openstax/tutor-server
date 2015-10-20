class CourseMembership::ApproveEnrollmentChange
  lev_routine express_output: :enrollment_change

  uses_routine AddUserAsPeriodStudent, as: :add_student
  uses_routine CourseMembership::AddEnrollment, as: :add_enrollment

  def exec(enrollment_change:, approved_by:)
    fatal_error(code: :already_approved,
                message: 'The given enrollment change request has already been approved') \
      if enrollment_change.approved?

    enrollment = enrollment_change.enrollment
    if enrollment.nil?
      # New student
      profile = enrollment_change.profile
      strategy = ::User::Strategies::Direct::User.new(profile)
      user = ::User::User.new(strategy: strategy)
      run(:add_student, user: user, period: enrollment_change.period)
    else
      # Existing student
      student = enrollment.student
      run(:add_enrollment, student: student, period: enrollment_change.period)
    end

    enrollment_change.approve_by(approved_by).save!
    outputs[:enrollment_change] = enrollment_change
  end
end
