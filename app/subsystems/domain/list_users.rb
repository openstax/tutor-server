class Domain::ListUsers
  lev_routine express_output: :users

  uses_routine UserProfile::ListProfiles,
    translations: { outputs: { type: :verbatim } },
    as: :list_profiles

  protected
  def exec
    run(:list_profiles)
    outputs[:users] = outputs.profiles.collect do |profile|
      {
        id: profile.id,
        account_id: profile.account_id,
        entity_user_id: profile.entity_user_id,
        username: profile.account.username,
        full_name: profile.account.full_name
      }
    end
  end
end

