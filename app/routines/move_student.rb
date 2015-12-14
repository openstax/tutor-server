class MoveStudent
  lev_routine outputs: { student: { name: CourseMembership::AddEnrollment,
                                    as: :add_enrollment } }

  def exec(period:, student:)
    run(:add_enrollment, period: period, student: student)
  end
end
