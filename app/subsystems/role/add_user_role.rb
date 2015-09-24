class Role::AddUserRole
  lev_routine

  protected

  def exec(user:, role:)
    ss_map = Role::Models::RoleUser.create(user_profile_id: user.id, role: role)
    transfer_errors_from(ss_map, {type: :verbatim}, true)
  end
end
