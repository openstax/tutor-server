class Role::GetUserRoles
  lev_routine express_output: :roles

  include VerifyAndGetIdArray

  protected

  def exec(users_or_user_ids, role_types = :any)
    user_ids = verify_and_get_id_array(users_or_user_ids, User::User)

    role_users = Role::Models::RoleUser.preload(:role).where(user_profile_id: user_ids)
    roles = role_users.map(&:role)

    role_types = [role_types].flatten.map(&:to_s)

    roles = roles.select{ |role| role_types.include?(role.role_type) } \
      unless role_types.any?{ |role_type| role_type == 'any' }

    outputs[:roles] = roles
  end
end
