class CourseMembership::CreateEnrollmentChange
  lev_routine express_output: :enrollment_change

  def exec(user:, period:, requires_enrollee_approval: true)
    outputs[:enrollment_change] = nil
  end
end
