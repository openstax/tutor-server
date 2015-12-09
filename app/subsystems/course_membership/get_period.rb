class CourseMembership::GetPeriod
  lev_routine outputs: { period: :_self }

  protected
  def exec(id:)
    model = CourseMembership::Models::Period.find(id)
    set(period: CourseMembership::Period.new(strategy: model.wrap))
  end
end
