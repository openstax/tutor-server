class CourseSs::AddStudent
  lev_routine

  protected

  def exec(course:, role:)
    ss_map = CourseSs::Student.create(entity_ss_course_id: course.id, entity_ss_role_id: role.id)
    transfer_errors_from(ss_map, {type: :verbatim}, true)
  end
end
