class CoursesConfirmEnrollment
  lev_handler

  uses_routine CourseMembership::GetPeriod, as: :get_period,
                                            translations: { outputs: { type: :verbatim } }
  uses_routine AddUserAsPeriodStudent

  paramify :enroll do
    attribute :enrollment_token, type: String
    attribute :student_id, type: String
  end

  protected

  def authorized?; true; end

  def handle
    run(:get_period, enrollment_code: enroll_params.enrollment_token)
    fatal_error(code: :enrollment_code_not_found) if outputs.period.nil?
    outputs.course = outputs.period.course

    run(AddUserAsPeriodStudent, user: caller, period: outputs.period,
                                student_identifier: enroll_params.student_id)
  end

end
