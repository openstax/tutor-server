class CourseMembership::UpdatePeriod
  lev_routine express_output: :period

  protected
  def exec(period:, name: nil, enrollment_code: nil, default_open_time: nil,
           default_due_time: nil)
    period.update_attributes(name: name || period.name,
                             enrollment_code: enrollment_code || period.enrollment_code,
                             default_open_time: default_open_time || period.default_open_time,
                             default_due_time: default_due_time || period.default_due_time)
    transfer_errors_from period, { type: :verbatim }, true
    outputs.period = period
  end
end
