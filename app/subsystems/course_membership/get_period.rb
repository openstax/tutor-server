class CourseMembership::GetPeriod
  lev_routine express_output: :period

  protected

  def exec(id:)
    model = CourseMembership::Models::Period.find(id)
    outputs.period = CourseMembership::Period.new(strategy: model.wrap)
  end
end
