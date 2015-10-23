class CourseMembership::UpdatePeriod
  lev_routine express_output: :period

  protected
  def exec(period:, name:)
    model = period.to_model
    model.update_attributes(name: name)
    outputs.period = period
  end
end
