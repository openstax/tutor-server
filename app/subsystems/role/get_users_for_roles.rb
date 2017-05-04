class Role::GetUsersForRoles
  lev_routine express_output: :users

  protected

  def exec(roles)
    role_ids = [roles].flatten.map(&:id)

    users = User::Models::Profile.joins(:role_users)
                                 .where(role_users: { entity_role_id: role_ids })
                                 .distinct

    outputs.users = users.map { |user| ::User::User.new(strategy: user.wrap) }
  end
end
