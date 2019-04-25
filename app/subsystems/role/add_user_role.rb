class Role::AddUserRole
  lev_routine

  protected

  def exec(user:, role:)
    role_user = Role::Models::RoleUser.create(user_profile_id: user.id, role: role)
    user.roles.reset
    transfer_errors_from(role_user, { type: :verbatim }, true)
  end
end
