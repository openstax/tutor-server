class CourseMembership::IsCourseTeacher
  lev_query

  protected
  def query(course:, roles:)
    role_ids = [roles].flatten.collect(&:id)
    CourseMembership::Models::Teacher.where{entity_course_id == course.id}
                                     .where{entity_role_id.in role_ids}.any?
  end
end
