class Role::CreateUserRole
  lev_routine express_output: :role

  uses_routine Role::AddUserRole

  protected

  def exec(user, role_type = :unassigned)
    outputs[:role] = ::Entity::Role.create!(role_type: role_type)
    run(Role::AddUserRole, user: user, role: outputs.role)
  end
end
