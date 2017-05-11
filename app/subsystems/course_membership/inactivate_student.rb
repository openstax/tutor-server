module CourseMembership
  class InactivateStudent
    lev_routine express_output: :student

    def exec(student:)
      fatal_error(code: :already_inactive,
                  message: 'Student is already inactive') if student.deleted?
      student.destroy
      student.clear_association_cache
      transfer_errors_from(student, { type: :verbatim }, true)
      outputs[:student] = student

      OpenStax::Biglearn::Api.update_rosters(course: student.course)
    end
  end
end
