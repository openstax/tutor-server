class Role::GetUserRoles
  lev_routine

  protected

  def exec(user)
    ss_maps  = Role::Models::User.includes(:role).where{entity_user_id == user.id}
    roles = ss_maps.collect{|ss_map| ss_map.role}
    outputs[:roles] = roles
  end
end
