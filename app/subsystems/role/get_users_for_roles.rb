class Role::GetUsersForRoles
  lev_routine express_output: :users

  protected

  def exec(roles)
    role_ids = [roles].flatten.compact.collect{|r| r.id}
    ss_maps = Role::Models::User.includes(:user).where{entity_role_id.in role_ids}
    outputs[:role_to_user_map] = Hash[ss_maps.collect{|ss_map| [ss_map.entity_role_id, ss_map.user]}]
    outputs[:users] = outputs[:role_to_user_map].values.uniq
  end
end
