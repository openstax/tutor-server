class Role::CreateUserRole
  lev_routine

  uses_routine Entity::CreateRole, translations: {type: :verbatim}
  uses_routine Role::AddUserRole, translations: {type: :verbatim}

  protected

  def exec(user)
    role = run(Entity::CreateRole).outputs.role
    run(Role::AddUserRole, user: user, role: role)
    outputs[:role] = role
  end
end
