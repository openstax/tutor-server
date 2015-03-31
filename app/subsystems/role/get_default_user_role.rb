class Role::GetDefaultUserRole
  lev_routine express_output: :role

  uses_routine Role::GetUserRoles
  uses_routine Role::CreateUserRole,
               translations: { outputs: { type: :verbatim } }

  protected

  def exec(user)
    run(Role::GetUserRoles, user, :default)
    existing_default_roles = outputs['[:role_get_user_roles, :roles]']

    if existing_default_roles.empty?
      run(Role::CreateUserRole, user, :default)
    else
      outputs[:role] = existing_default_roles.first
    end
  end
end
