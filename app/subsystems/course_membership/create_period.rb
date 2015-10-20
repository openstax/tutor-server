class CourseMembership::CreatePeriod
  lev_routine express_output: :period

  protected

  def exec(course:, name:)
    period = CourseMembership::Models::Period.new(name: name)
    save_with_course_association_cache_update(course, period)
    transfer_errors_from(period, {type: :verbatim}, true)
    outputs[:period] = CourseMembership::Period.new(period)
  end

  private
  def save_with_course_association_cache_update(course, period)
    course.periods << period
    period.save
  end
end
