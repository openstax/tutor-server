class Role::CreateUserRole
  lev_routine express_output: :role

  uses_routine Role::AddUserRole, as: :add_user_role

  protected

  def exec(user, role_type = :unassigned)
    outputs.role = ::Entity::Role.create!(role_type: role_type)

    run(:add_user_role, user: user, role: outputs.role)
  end
end
