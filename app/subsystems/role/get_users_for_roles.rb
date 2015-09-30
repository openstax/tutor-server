class Role::GetUsersForRoles
  lev_routine express_output: :users

  protected

  def exec(roles)
    role_ids = [roles].flatten.compact.collect(&:id)
    role_users = Role::Models::RoleUser.includes(:profile).where{entity_role_id.in role_ids}
    outputs[:users] = role_users.collect do |role_user|
      profile = role_user.profile
      strategy = ::User::Strategies::Direct::User.new(profile)
      ::User::User.new(strategy: strategy)
    end.uniq
  end
end
