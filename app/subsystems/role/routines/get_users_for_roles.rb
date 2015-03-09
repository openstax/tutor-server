class Role::GetUsersForRoles
  lev_routine

  protected

  def exec(roles)
    role_ids = roles.collect{|r| r.id}
    ss_maps = Role::User.where{entity_role_id.in role_ids}
    outputs[:users] = ss_maps.collect{|ss_map| ss_map.entity_user}.uniq
  end
end
