class Role::AddUserRole
  lev_routine

  protected

  def exec(user:, role:)
    if user.is_a?(UserProfile::Models::Profile)
      user = user.entity_user
    end
    ss_map = Role::Models::User.create(user: user, role: role)
    transfer_errors_from(ss_map, {type: :verbatim}, true)
  end
end
