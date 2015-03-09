class CourseMembership::AddTeacher
  lev_routine

  protected

  def exec(course:, role:)
    ss_map = CourseMembership::Teacher.create(entity_course_id: course.id, entity_role_id: role.id)
    transfer_errors_from(ss_map, {type: :verbatim}, true)
  end
end
