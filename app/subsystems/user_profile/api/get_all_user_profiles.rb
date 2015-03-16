class UserProfile::GetAllUserProfiles
  lev_routine

  protected

  def exec
    users = UserProfile::Profile.includes(:account, :entity_user)
    outputs[:profiles] = users.find_each.collect do |profile|
      {
        profile_id: profile.id,
        entity_user_id: profile.entity_user_id,
        full_name: profile.account.full_name
      }
    end
  end
end
