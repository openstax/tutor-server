class CourseMembership::CreatePeriod
  lev_routine outputs: { period: :_self }

  protected

  def exec(course:, name:)
    period = CourseMembership::Models::Period.new(name: name)
    course.periods << period # fixes association cache bug
    transfer_errors_from(period, {type: :verbatim}, true)
    strategy = CourseMembership::Strategies::Direct::Period.new(period)
    set(period: CourseMembership::Period.new(strategy: strategy))
  end
end
