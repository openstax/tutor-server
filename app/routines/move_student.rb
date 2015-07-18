class MoveStudent
  lev_routine express_output: :student

  uses_routine CourseMembership::CreateEnrollment,
    translations: { outputs: { type: :verbatim } },
    as: :create_enrollment

  def exec(period:, student:)
    run(:create_enrollment, period: period, student: student)
  end
end
