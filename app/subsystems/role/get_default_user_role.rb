class Role::GetDefaultUserRole
  lev_routine express_output: :role

  uses_routine Role::GetUserRoles
  uses_routine Role::CreateUserRole,
               translations: { outputs: { type: :verbatim } }

  protected

  def exec(user)
    existing_default_roles =
      run(Role::GetUserRoles, user, :default).outputs.roles

    if existing_default_roles.empty?
      run(Role::CreateUserRole, user, :default)
    else
      outputs[:role] = existing_default_roles.first
    end
  end
end
