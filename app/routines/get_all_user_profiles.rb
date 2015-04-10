class GetAllUserProfiles
  lev_routine express_output: :profiles

  uses_routine UserProfile::ListProfiles,
    translations: { outputs: { type: :verbatim } },
    as: :get_all_user_profiles

  protected

  def exec
    run(:get_all_user_profiles)
  end
end
