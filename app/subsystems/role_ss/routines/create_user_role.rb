class RoleSs::CreateUserRole
  lev_routine

  uses_routine EntitySs::CreateRole, translations: {type: :verbatim}
  uses_routine RoleSs::AddUserRole, translations: {type: :verbatim}

  protected

  def exec(user)
    role = run(EntitySs::CreateRole).outputs.role
    run(RoleSs::AddUserRole, user: user, role: role)
    outputs[:role] = role
  end
end
