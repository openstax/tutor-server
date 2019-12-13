class CourseMembership::UpdatePeriod
  lev_routine express_output: :period

  protected
  def exec(period:, name: nil, enrollment_code: nil)
    period.update_attributes(name: name || period.name,
                             enrollment_code: enrollment_code || period.enrollment_code)
    transfer_errors_from period, { type: :verbatim }, true
    outputs.period = period
  end
end
