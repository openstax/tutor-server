class CourseMembership::CreateEnrollmentChange
  lev_routine express_output: :enrollment_change

  uses_routine Role::GetUserRoles, as: :get_roles
  uses_routine GetCourseEcosystem, as: :get_ecosystem

  def exec(user:, period:, book_uuid: nil, requires_enrollee_approval: true)
    user_role_ids = run(:get_roles, user, 'student').outputs.roles.map(&:id)

    ecosystem = run(:get_ecosystem, course: period.course).outputs.ecosystem
    # Assumes 1 book in the ecosystem
    period_book_uuid = ecosystem.nil? ? nil : ecosystem.books.first.uuid

    fatal_error(code: :enrollment_code_does_not_match_book,
                message: 'The given enrollment code does not match the current book') \
      if book_uuid.present? && book_uuid != period_book_uuid

    course = period.course

    user_students = course.students.with_deleted.where(entity_role_id: user_role_ids).to_a

    # This code does NOT support users with multiple "students" (teachers) trying to change periods
    fatal_error(code: :multiple_roles,
                message: 'Users with multiple roles in a course cannot use self-enrollment') \
      if user_students.size > 1

    student = user_students.first

    if student.present?
      fatal_error(code: :dropped_student,
                  message: 'User cannot re-enroll in a course from which they were dropped') \
        if student.deleted?

      enrollment = student.latest_enrollment

      fatal_error(code: :already_enrolled,
                  message: 'User is already enrolled in the course') \
        if enrollment.period.id == period.id
    end

    enrollment_change_model = CourseMembership::Models::EnrollmentChange.create(
      user_profile_id: user.id, enrollment: enrollment, period: period.to_model,
      requires_enrollee_approval: requires_enrollee_approval
    )
    transfer_errors_from(enrollment_change_model, {type: :verbatim}, true)

    enrollment_change = CourseMembership::EnrollmentChange.new(
      strategy: enrollment_change_model.wrap
    )
    outputs[:enrollment_change] = enrollment_change
  end
end
