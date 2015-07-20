class CourseMembership::IsCourseStudent
  lev_routine express_output: :is_course_student

  protected

  def exec(course:, roles:)
    outputs[:is_course_student] = course.students.where(entity_role_id: roles).exists?
  end
end
