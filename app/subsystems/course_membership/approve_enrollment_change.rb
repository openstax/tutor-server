class CourseMembership::ApproveEnrollmentChange
  lev_routine express_output: :enrollment_change

  def exec(enrollment_change:, approved_by:)
    outputs[:enrollment_change] = nil
  end
end
