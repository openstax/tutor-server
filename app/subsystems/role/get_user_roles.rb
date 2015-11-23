class Role::GetUserRoles
  lev_routine outputs: {
    roles: :_self
  }

  include VerifyAndGetIdArray

  protected
  def exec(users_or_user_ids, role_types=:any)
    user_ids = verify_and_get_id_array(users_or_user_ids, User::User)

    ss_maps = Role::Models::RoleUser.includes(:role).where{user_profile_id.in user_ids}
    roles = ss_maps.collect{|ss_map| ss_map.role}

    if role_types != :any
      role_types = [role_types].flatten.collect{|rt| rt.to_s}
      roles = roles.select { |role| role_types.include?(role.role_type) }
    end

    set(roles: roles)
  end
end
