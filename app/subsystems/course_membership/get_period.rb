class CourseMembership::GetPeriod
  lev_routine express_output: :period

  protected
  def exec(id:)
    model = CourseMembership::Models::Period.find(id)
    strategy = CourseMembership::Strategies::Direct::Period.new(model)
    outputs.period = CourseMembership::Period.new(strategy: strategy)
  end
end
