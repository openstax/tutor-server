class Role::GetDefaultUserRole
  lev_routine express_output: :role

  uses_routine Role::CreateUserRole, as: :create_user_role,
                                     translations: { outputs: { type: :verbatim } }

  protected

  def exec(user)
    existing_default_roles = user.roles.default

    if existing_default_roles.empty?
      run(:create_user_role, user, :default)
    else
      outputs.role = existing_default_roles.order(:id).first
    end
  end
end
