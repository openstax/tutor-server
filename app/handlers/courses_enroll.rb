class CoursesEnroll
  lev_handler

  uses_routine AddUserAsPeriodStudent, ignored_errors: [:user_is_already_teacher_of_course]

  protected
  def authorized?; true; end

  def handle
    after_transaction { raise_handled_exceptions! }

    enrollment_code = params[:enrollment_code].gsub(/-/,' ')
    period = CourseMembership::Models::Period.find_by(enrollment_code: enrollment_code)
    fatal_error(code: :enrollment_code_not_found) if period.nil?

    outputs.course = period.course

    run(AddUserAsPeriodStudent, user: current_user, period: period)
  end

  private
  def raise_handled_exceptions!
    raise self.class.handled_exceptions[errors.first.code] if errors.any?
  end

  def self.handled_exceptions
    @@handled_exceptions ||= {
      enrollment_code_not_found: EnrollmentCodeNotFound
    }
  end
end

class EnrollmentCodeNotFound < StandardError; end
