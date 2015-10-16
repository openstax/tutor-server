class CourseMembership::GetPeriod
  lev_routine express_output: :period

  protected
  def exec(id:)
    period = CourseMembership::Models::Period.find(id)
    outputs.period = CourseMembership::Period.new(period)
  end
end
