# Checks if an enrollment code is valid for a given book
class CourseMembership::ValidateEnrollmentParameters

  lev_routine express_output: :period

  protected

  def exec(book_uuid:, enrollment_code:)
    outputs.period = CourseMembership::Models::Period.find_by(enrollment_code: enrollment_code)

    fatal_error(code: :invalid_enrollment_code) if outputs.period.nil?
    fatal_error(code: :preview_course) if outputs.period.course.is_preview
    fatal_error(code: :course_ended) if outputs.period.course.ended?
    fatal_error(code: :enrollment_code_does_not_match_book) \
      if outputs.period.course.ecosystems.none? do |ecosystem|
      ecosystem.books.any?{ |book| book.uuid == book_uuid }
    end
  end

end
