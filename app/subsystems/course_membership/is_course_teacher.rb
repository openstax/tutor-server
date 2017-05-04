class CourseMembership::IsCourseTeacher
  lev_routine express_output: :is_course_teacher

  protected

  def exec(course:, roles:)
    role_ids = [roles].flatten.map(&:id)

    outputs.is_course_teacher = CourseMembership::Models::Teacher.exists?(course: course,
                                                                          entity_role_id: role_ids)
  end
end
