class MoveStudent
  lev_routine express_output: :student

  uses_routine CourseMembership::AddEnrollment,
    translations: { outputs: { type: :verbatim } },
    as: :add_enrollment

  def exec(period:, student:)
    run(:add_enrollment, period: period, student: student)
  end
end
