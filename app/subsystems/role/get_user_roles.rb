class Role::GetUserRoles
  lev_routine express_output: :roles

  include VerifyAndGetIdArray

  protected

  def exec(users_or_user_ids, role_types=:any)
    user_ids = verify_and_get_id_array(users_or_user_ids, User::User)

    role_users = Role::Models::RoleUser.includes(:role).where{user_profile_id.in user_ids}
    roles = role_users.map(&:role)

    if role_types != :any
      role_types = [role_types].flatten.map(&:to_s)
      roles = roles.select{|role| role_types.include?(role.role_type) && role.send(role.role_type).present? }
    end

    outputs[:roles] = roles
  end
end
