class RoleSs::AddUserRole
  lev_routine

  protected

  def exec(user:, role:)
    ss_map = RoleSs::UserRoleMap.create(entity_ss_user_id: user.id, entity_ss_role_id: role.id)
    transfer_errors_from(ss_map, {type: :verbatim}, true)
  end
end
