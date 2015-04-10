class UserProfile::ListProfiles
  lev_routine express_output: :profiles

  protected
  def exec
    profiles = UserProfile::Models::Profile.all
    outputs[:profiles] = profiles.collect do |profile|
      {
        id: profile.id,
        account_id: profile.account_id,
        entity_user_id: profile.entity_user_id,
        full_name: profile.full_name,
        username: profile.account.username
      }
    end
  end
end

