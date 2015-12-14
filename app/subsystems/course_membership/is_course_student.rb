class CourseMembership::IsCourseStudent
  lev_query

  protected
  def query(course:, roles:)
    course.students.where(entity_role_id: roles).exists?
  end
end
