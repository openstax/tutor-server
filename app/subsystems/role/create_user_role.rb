class Role::CreateUserRole
  lev_routine express_output: :role

  protected

  def exec(user, role_type = :unassigned)
    outputs.role = ::Entity::Role.new(role_type: role_type)
    user.roles << outputs.role
  end
end
