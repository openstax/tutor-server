class Entity::CreateRole
  lev_routine

  protected

  def exec(role_type = :unassigned)
    role = Entity::Role.create(role_type: role_type)
    transfer_errors_from(role, { type: :verbatim }, true)
    outputs[:role] = role
  end
end
