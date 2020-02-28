class CourseMembership::CreateEnrollmentChange
  lev_routine express_output: :enrollment_change

  uses_routine GetUserCourseRoles, as: :get_user_course_roles
  uses_routine GetCourseEcosystem, as: :get_ecosystem

  def exec(user:, enrollment_code:, book_uuid: nil, requires_enrollee_approval: true)
    period = CourseMembership::Models::Period.find_by(enrollment_code: enrollment_code)

    fatal_error(code: :invalid_enrollment_code,
                message: 'The given enrollment code is invalid') if period.nil?

    course = period.course
    fatal_error(code: :preview_course,
                message: 'You cannot enroll in a preview course') if course.is_preview

    fatal_error(code: :course_ended,
                message: 'The course associated with the given enrollment code has ended') \
      if course.ended?

    roles = run(
      :get_user_course_roles,
      user: user,
      courses: course,
      types: [:student, :teacher],
      include_dropped_students: true
    ).outputs.roles.to_a

    fatal_error(
      code: :is_teacher,
      message: 'You cannot enroll as both a student and a teacher',
      data: { course_name: course.name }) if roles.any? do |role|
        role.teacher? && role.teacher.present? && role.teacher.course == course
      end

    student_roles = roles.select do |role|
      role.student? && role.student.present? && !role.student.period.archived?
    end

    ecosystem = run(:get_ecosystem, course: course).outputs.ecosystem
    # Assumes 1 book in the ecosystem
    course_book_uuid = ecosystem.nil? ? nil : ecosystem.books.first.try!(:uuid)

    fatal_error(code: :enrollment_code_does_not_match_book,
                message: 'The given enrollment code does not match the current book') \
      if book_uuid.present? && book_uuid != course_book_uuid

    course_roles, other_roles = student_roles.partition { |role| role.student.course == course }

    if course_roles.any?
      # We consider that your most recent role in a course is always the active one
      student = course_roles.max_by(&:created_at).student

      fatal_error(code: :dropped_student,
                  message: 'You cannot re-enroll in a course from which you were dropped') \
        if student.dropped?

      enrollment = student.latest_enrollment

      fatal_error(code: :already_enrolled, message: 'You are already enrolled in the course') \
        if enrollment.period.id == period.id
    else
      enrollment = nil
    end

    outputs.enrollment_change = CourseMembership::Models::EnrollmentChange.create(
      user_profile_id: user.id,
      enrollment: enrollment,
      period: period,
      requires_enrollee_approval: requires_enrollee_approval
    )
    transfer_errors_from(outputs.enrollment_change, { type: :verbatim }, true)
  end
end
