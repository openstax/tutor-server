class CourseMembership::IsCourseTeacher
  lev_routine express_output: :is_course_teacher

  protected

  def exec(course:, roles:)
    role_ids = [roles].flatten.map(&:id)
    outputs[:is_course_teacher] =
      CourseMembership::Models::Teacher.where{course_profile_course_id == course.id}
                                       .where{entity_role_id.in role_ids}.any?
  end
end
