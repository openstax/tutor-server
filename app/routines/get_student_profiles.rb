class GetStudentProfiles
  lev_routine express_output: :profiles

  uses_routine CourseMembership::GetStudents,
               as: :get_students,
               translations: { outputs: { type: :verbatim } }

  uses_routine Role::GetUsersForRoles,
               as: :get_users_for_roles,
               translations: { outputs: { type: :verbatim } }

  uses_routine UserProfile::GetUserFullNames,
               as: :get_user_full_names,
               translations: { outputs: { type: :verbatim } }

  protected
  def exec(period: period)
    student_roles = run(:get_students, period: period).outputs.students
    users = run(:get_users_for_roles, student_roles).outputs.users
    names = run(:get_user_full_names, users).outputs.full_names
    role_users = Role::Models::User.where(entity_user_id: users.collect(&:id))

    outputs[:profiles] = student_roles.collect do |role|
      user_id = role_users.select { |u| u.entity_role_id == role.id }.first.entity_user_id
      name = names.select { |n| n.entity_user_id == user_id }.first
      {
        entity_user_id: user_id,
        entity_role_id: role.id,
        full_name: name.full_name
      }
    end
  end
end
