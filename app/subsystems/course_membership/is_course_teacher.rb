class CourseMembership::IsCourseTeacher
  lev_routine express_output: :is_course_teacher

  protected

  def exec(course:, roles:, include_deleted_teachers: false)
    teachers = course.teachers.where(entity_role_id: roles)
    teachers = teachers.without_deleted unless include_deleted_teachers

    outputs.teacher = teachers.find { |teacher| !teacher.deleted? }
    outputs.is_deleted = outputs.teacher.nil? && !teachers.empty?
    outputs.is_course_teacher = outputs.teacher.present? || outputs.is_deleted
  end
end
