class Domain::ListUsers
  lev_routine express_output: :users

  uses_routine UserProfile::ListProfiles,
    translations: { outputs: { map: { profiles: :users } } },
    as: :list_profiles

  protected
  def exec
    run(:list_profiles)
    outputs[:users] = outputs.users.collect do |account|
      {
        id: account.id,
        username: account.username
      }
    end
  end
end

