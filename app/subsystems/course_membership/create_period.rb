class CourseMembership::CreatePeriod
  lev_routine express_output: :period

  protected

  def exec(course:, name: nil, enrollment_code: nil)
    name ||= (course.periods.count + 1).ordinalize
    period = CourseMembership::Models::Period.new(name: name, enrollment_code: enrollment_code)
    course.periods << period
    transfer_errors_from(period, {type: :verbatim}, true)
    strategy = CourseMembership::Strategies::Direct::Period.new(period)
    outputs[:period] = CourseMembership::Period.new(strategy: strategy)

    OpenStax::Biglearn::Api.update_rosters(course: course) if course.course_ecosystems.any?
  end
end
