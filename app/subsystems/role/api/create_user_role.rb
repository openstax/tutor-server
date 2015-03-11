class Role::CreateUserRole
  lev_routine

  uses_routine Entity::CreateRole, translations: {outputs: {type: :verbatim}}
  uses_routine Role::AddUserRole

  protected

  def exec(user)
    run(Entity::CreateRole)
    run(Role::AddUserRole, user: user, role: outputs.role)
  end
end
