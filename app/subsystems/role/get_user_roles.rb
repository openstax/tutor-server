class Role::GetUserRoles
  lev_routine

  protected

  def exec(users_or_user_ids, role_types=:any)
    users_or_user_ids = [users_or_user_ids].flatten

    user_ids = users_or_user_ids.first.is_a?(Integer) ? 
                 users_or_user_ids :
                 users_or_user_ids.collect{|u| u.id}

    ss_maps  = Role::Models::User.includes(:role).where{entity_user_id.in user_ids}
    roles = ss_maps.collect{|ss_map| ss_map.role}

    if role_types != :any
      role_types = [role_types].flatten
      roles = roles.select{|role| role_types.include?(role.role_type)}
    end

    outputs[:roles] = roles
  end
end
