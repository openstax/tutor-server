class Role::AddUserRole
  lev_routine

  protected

  def exec(user:, role:)
    ss_map = Role::Models::RoleUser.create(user: user, role: role)
    transfer_errors_from(ss_map, {type: :verbatim}, true)
  end
end
