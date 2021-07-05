class CourseMembership::IsCourseTeacher
  lev_routine express_output: :is_course_teacher

  protected

  def exec(course:, roles:, include_deleted_teachers: false)
    outputs.teachers = course.teachers.where(entity_role_id: roles)
    outputs.teachers = outputs.teachers.without_deleted unless include_deleted_teachers

    outputs.teacher = outputs.teachers.to_a.find { |teacher| !teacher.deleted? }
    outputs.is_deleted = outputs.teacher.nil? && !outputs.teachers.empty?
    outputs.is_course_teacher = outputs.teacher.present? || outputs.is_deleted
  end
end
