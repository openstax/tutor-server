class RoleSs::GetUserRoles
  lev_routine

  protected

  def exec(user)
    ss_maps  = RoleSs::UserRoleMap.includes(:entity_ss_role).where{entity_ss_user_id == user.id}
    roles = ss_maps.collect{|ss_map| ss_map.entity_ss_role}
    outputs[:roles] = roles
  end
end
