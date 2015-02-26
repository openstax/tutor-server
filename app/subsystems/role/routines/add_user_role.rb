class Role::AddUserRole
  lev_routine

  protected

  def exec(user:, role:)
    ss_map = Role::User.create(entity_user_id: user.id, entity_role_id: role.id)
    transfer_errors_from(ss_map, {type: :verbatim}, true)
  end
end
