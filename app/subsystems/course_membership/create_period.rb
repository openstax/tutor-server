class CourseMembership::CreatePeriod
  lev_routine express_output: :period

  protected

  def exec(course:, name:, enrollment_code: nil)
    period = CourseMembership::Models::Period.new(name: name, enrollment_code: enrollment_code)
    course.periods << period # fixes association cache bug
    transfer_errors_from(period, {type: :verbatim}, true)
    strategy = CourseMembership::Strategies::Direct::Period.new(period)
    outputs[:period] = CourseMembership::Period.new(strategy: strategy)
  end
end
