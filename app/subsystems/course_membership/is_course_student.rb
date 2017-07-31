class CourseMembership::IsCourseStudent
  lev_routine express_output: :is_course_student

  protected

  def exec(course:, roles:, include_dropped_students: false, include_archived_periods: false)
    students = course.students.where(entity_role_id: roles).preload(enrollments: :period)
    students = students.without_deleted unless include_dropped_students

    is_dropped = false
    is_archived = false
    valid_student = students.find do |student|
      is_dropped = true if student.dropped?
      is_archived = true if student.period.archived?

      !student.dropped? && !student.period.archived?
    end

    outputs.is_dropped = valid_student.nil? && is_dropped if include_dropped_students
    outputs.is_archived = valid_student.nil? && is_archived if include_archived_periods

    outputs.is_course_student = !!(
      valid_student.present? || outputs.is_dropped || outputs.is_archived
    )

    outputs[:student] = valid_student
  end
end
