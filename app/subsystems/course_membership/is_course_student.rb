class CourseMembership::IsCourseStudent
  lev_routine express_output: :is_course_student

  protected

  def exec(course:, roles:, include_dropped: false, include_archived: false)
    relation = course.students
    relation = relation.preload(enrollments: :period) unless include_archived
    relation = relation.with_deleted if include_dropped
    students = relation.where(entity_role_id: roles)

    valid_student = students.detect do | student |
      ! ( student.deleted? || student.period.deleted? )
    end

    if include_dropped
      outputs[:is_dropped] = valid_student.nil? && students.any? { | student | student.deleted? }
    end

    if include_archived
      outputs[:is_archived] = valid_student.nil? && students.any? { | student | student.period.deleted? }
    end

    outputs[:is_course_student] = !!(valid_student.present? || outputs[:is_dropped] || outputs[:is_archived])
  end
end
