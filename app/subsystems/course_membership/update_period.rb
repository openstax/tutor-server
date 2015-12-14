class CourseMembership::UpdatePeriod
  lev_routine outputs: { period: :_self }

  protected
  def exec(period:, name: nil, enrollment_code: nil)
    model = period.to_model
    model.update_attributes(name: name || period.name,
                            enrollment_code: enrollment_code || period.enrollment_code)
    set(period: period)
  end
end
