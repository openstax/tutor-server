# Checks if an enrollment code is valid for a course
class CourseMembership::ValidateEnrollmentParameters

  lev_routine express_output: :is_valid

  protected

  def exec(book_uuid:, enrollment_code: )
    ecosystem = Content::Ecosystem.find_by_book_uuid(book_uuid)
    if ecosystem
      period = CourseMembership::Models::Period.find_by(enrollment_code: enrollment_code)
    end
    outputs[:is_valid] = !!(ecosystem && period && period.course.ecosystems.exists?(id: ecosystem.id))
  end

end
