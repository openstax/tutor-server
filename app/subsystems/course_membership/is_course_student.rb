class CourseMembership::IsCourseStudent
  lev_routine express_output: :is_course_student

  protected

  def exec(course:, roles:, include_dropped_students: false, include_archived_periods: false)
    students = course.students.where(entity_role_id: roles).preload(enrollments: :period)
    students = students.without_deleted unless include_dropped_students
    students = students.reject { |student| student.period.archived? } \
      unless include_archived_periods

    outputs.is_dropped = false
    outputs.is_archived = false
    outputs.student = students.find do |student|
      outputs.is_dropped = true if student.dropped?
      outputs.is_archived = true if student.period.archived?

      !student.dropped? && !student.period.archived?
    end

    outputs.is_course_student = outputs.student.present? ||
                                outputs.is_dropped ||
                                outputs.is_archived
  end
end
