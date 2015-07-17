class Role::GetUsersForRoles
  lev_routine express_output: :users

  protected

  def exec(roles)
    role_ids = [roles].flatten.compact.collect(&:id)
    ss_maps = Role::Models::RoleUser.includes(:user).where{entity_role_id.in role_ids}
    outputs[:users] = ss_maps.collect(&:user).uniq
  end
end
