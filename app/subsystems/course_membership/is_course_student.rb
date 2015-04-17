class CourseMembership::IsCourseStudent
  lev_routine express_output: :is_course_student

  protected

  def exec(course:, roles:)
    role_ids = [roles].flatten.collect{|r| r.id}
    outputs[:is_course_student] =
      CourseMembership::Models::Student.where{entity_course_id == course.id}
                                       .where{entity_role_id >> role_ids}.any?
  end
end
