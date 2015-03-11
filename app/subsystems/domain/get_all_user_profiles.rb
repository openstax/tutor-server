class Domain::GetAllUserProfiles
  lev_routine

  uses_routine LegacyUser::GetAllUserProfiles,
    translations: { outputs: { type: :verbatim } },
    as: :get_all_user_profiles

  protected

  def exec
    run(:get_all_user_profiles)
  end
end
