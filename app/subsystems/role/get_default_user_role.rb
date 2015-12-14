class Role::GetDefaultUserRole
  lev_routine outputs: { role: :_self },
              uses: [Role::GetUserRoles, Role::CreateUserRole]

  protected

  def exec(user)
    existing_default_roles = run(:role_get_user_roles, user, :default).roles

    if existing_default_roles.empty?
      set(role: run(:role_create_user_role, user, :default).role)
    else
      set(role: existing_default_roles.first)
    end
  end
end
