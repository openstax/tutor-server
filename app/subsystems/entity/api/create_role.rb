class Entity::CreateRole
  lev_routine

  protected

  def exec
    role = Entity::Role.create
    transfer_errors_from(role, {type: :verbatim}, true)
    outputs[:role] = role
  end
end
