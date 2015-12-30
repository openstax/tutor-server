# Checks if an enrollment code is valid for a course
class CourseMembership::ValidateEnrollmentParameters

  lev_routine express_output: :is_valid

  protected

  def exec(book_uuid:, enrollment_code:)
    period = CourseMembership::Models::Period.find_by(enrollment_code: enrollment_code)
    outputs[:is_valid] = !!period && period.course.ecosystems.any?{|ecosystem|
      ecosystem.books.any?{|book| book.uuid == book_uuid}
    }
  end

end
