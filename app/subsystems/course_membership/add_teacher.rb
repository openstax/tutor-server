class CourseMembership::AddTeacher
  lev_routine

  protected

  def exec(course:, role:)
    outputs.teacher = CourseMembership::Models::Teacher.create(course_profile_course_id: course.id,
                                                               entity_role_id: role.id)
    transfer_errors_from(outputs.teacher, {type: :verbatim}, true)
  end
end
