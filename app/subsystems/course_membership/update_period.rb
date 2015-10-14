class CourseMembership::UpdatePeriod
  lev_routine express_output: :period

  protected
  def exec(period:, name:)
    period.update_attributes(name: name)
    outputs.period = CourseMembership::Period.new(period.reload)
  end
end
