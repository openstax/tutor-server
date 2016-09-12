class CourseMembership::IsCourseStudent
  lev_routine express_output: :is_course_student

  protected

  def exec(course:, roles:, include_dropped: false, include_archived: false)
    relation = course.students
    relation = relation.preload(enrollments: :period) unless include_archived
    relation = relation.with_deleted if include_dropped
    students = relation.where(entity_role_id: roles)

    outputs[:is_course_student] = students.any? do |student|
      student.present? && (include_archived || !student.period.deleted?)
    end
  end
end
