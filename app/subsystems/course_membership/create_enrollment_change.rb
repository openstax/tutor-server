class CourseMembership::CreateEnrollmentChange
  lev_routine express_output: :enrollment_change

  uses_routine Role::GetUserRoles, as: :get_roles
  uses_routine GetCourseEcosystem, as: :get_ecosystem

  def exec(user:, period:, book_uuid: nil, requires_enrollee_approval: true)
    student_roles = run(:get_roles, user, 'student').outputs.roles.reject do |role|
      role.student.period.deleted?
    end

    course = period.course

    ecosystem = run(:get_ecosystem, course: course).outputs.ecosystem
    # Assumes 1 book in the ecosystem
    course_book_uuid = ecosystem.nil? ? nil : ecosystem.books.first.uuid

    fatal_error(code: :enrollment_code_does_not_match_book,
                message: 'The given enrollment code does not match the current book') \
      if book_uuid.present? && book_uuid != course_book_uuid

    course_roles, other_roles = student_roles.partition{ |role| role.student.course == course }

    if course.is_concept_coach
      # Detect conflicting concept coach courses (other CC courses that use the same book)
      # If any conflicts are detected, simply display an alert
      same_book_other_roles = other_roles.select do |role|
        other_course = role.student.course
        next false unless other_course.is_concept_coach

        other_ecosystem = run(:get_ecosystem, course: other_course).outputs.ecosystem
        next false if other_ecosystem.nil?

        other_ecosystem.books.first.uuid == course_book_uuid
      end

      same_book_other_enrollments = same_book_other_roles.map do |role|
        role.student.latest_enrollment
      end

      latest_other_enrollment = same_book_other_enrollments.max_by(&:created_at)
    else
      latest_other_enrollment = nil
    end

    if course_roles.any?
      # We consider that your most recent role in a course is always the active one
      student = course_roles.max_by(&:created_at).student

      fatal_error(code: :dropped_student,
                  message: 'You cannot re-enroll in a course from which you were dropped') \
        if student.deleted?

      enrollment = student.latest_enrollment

      conflicting_enrollment = latest_other_enrollment \
        if latest_other_enrollment.present? &&
           latest_other_enrollment.created_at >= enrollment.created_at

      fatal_error(code: :already_enrolled, message: 'You are already enrolled in the course') \
        if enrollment.period.id == period.id && conflicting_enrollment.nil?
    else
      enrollment = nil
      conflicting_enrollment = latest_other_enrollment
    end

    enrollment_change_model = CourseMembership::Models::EnrollmentChange.create(
      user_profile_id: user.id,
      enrollment: enrollment,
      period: period.to_model,
      requires_enrollee_approval: requires_enrollee_approval,
      conflicting_enrollment: conflicting_enrollment
    )
    transfer_errors_from(enrollment_change_model, {type: :verbatim}, true)

    enrollment_change = CourseMembership::EnrollmentChange.new(
      strategy: enrollment_change_model.wrap
    )
    outputs[:enrollment_change] = enrollment_change
  end
end
