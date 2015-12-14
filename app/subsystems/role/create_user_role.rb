class Role::CreateUserRole
  lev_routine outputs: { role: :_self },
              uses: Role::AddUserRole

  protected
  def exec(user, role_type = :unassigned)
    set(role: ::Entity::Role.create!(role_type: role_type))
    run(:role_add_user_role, user: user, role: result.role)
  end
end
