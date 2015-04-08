class GetAllUserProfiles
  lev_routine

  uses_routine UserProfile::GetAllUserProfiles,
    translations: { outputs: { type: :verbatim } },
    as: :get_all_user_profiles

  protected

  def exec
    run(:get_all_user_profiles)
  end
end
