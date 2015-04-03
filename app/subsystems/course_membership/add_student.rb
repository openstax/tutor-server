class CourseMembership::AddStudent
  lev_routine

  uses_routine Role::CreateUserRole

  protected

  def exec(course:, role:)
    user = Entity::User.create!
    Role::AddUserRole.call(user: user, role: role)
    ss_map = CourseMembership::Models::Student.create(entity_course_id: course.id, entity_role_id: role.id)
    transfer_errors_from(ss_map, {type: :verbatim}, true)
  end
end
