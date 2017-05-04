class Role::GetUserRoles
  lev_routine express_output: :roles

  protected

  def exec(users, role_types = :any)
    user_ids = [users].flatten.map(&:id)

    roles = Entity::Role.joins(:role_user).where(role_user: { user_profile_id: user_ids })

    role_types = [role_types].flatten.map(&:to_s)

    roles = roles.where(role_type: Entity::Role.role_types.values_at(*role_types)) \
      unless role_types.any? { |role_type| role_type == 'any' }

    outputs.roles = roles
  end
end
