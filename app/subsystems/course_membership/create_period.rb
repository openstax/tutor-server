class CourseMembership::CreatePeriod
  lev_routine express_output: :period

  protected

  def exec(course:, name:)
    period = CourseMembership::Models::Period.create(course: course, name: name)
    transfer_errors_from(period, {type: :verbatim}, true)
    outputs[:period] = CourseMembership::Period.new(period)
  end
end
