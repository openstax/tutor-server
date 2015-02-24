class EntitySs::CreateRole
  lev_routine

  protected

  def exec
    role = EntitySs::Role.create
    transfer_errors_from(role, {type: :verbatim}, true)
    outputs[:role] = role
  end
end
