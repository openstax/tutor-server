class Role::GetDefaultUserRole
  lev_routine express_output: :role

  uses_routine Role::GetUserRoles, as: :get_user_roles
  uses_routine Role::CreateUserRole, as: :create_user_role,
                                     translations: { outputs: { type: :verbatim } }

  protected

  def exec(user)
    existing_default_roles = run(:get_user_roles, user, :default).outputs.roles

    if existing_default_roles.empty?
      run(:create_user_role, user, :default)
    else
      outputs.role = existing_default_roles.first
    end
  end
end
