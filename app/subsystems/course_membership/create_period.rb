class CourseMembership::CreatePeriod
  lev_routine express_output: :period

  protected

  def exec(course:, name: nil, enrollment_code: nil, uuid: nil)
    name ||= (course.periods.count + 1).ordinalize
    uuid ||= SecureRandom.uuid
    outputs.period = CourseMembership::Models::Period.new(
      name: name, enrollment_code: enrollment_code, uuid: uuid
    )
    course.periods << outputs.period
    transfer_errors_from outputs.period, { type: :verbatim }, true
  end
end
