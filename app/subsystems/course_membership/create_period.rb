class CourseMembership::CreatePeriod
  lev_routine express_output: :period

  protected

  def exec(course:, name:)
    period = CourseMembership::Models::Period.new(name: name)
    course.periods << period # fixes association cache bug
    transfer_errors_from(period, {type: :verbatim}, true)
    outputs[:period] = CourseMembership::Period.new(period)
  end
end
