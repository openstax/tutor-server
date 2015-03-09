class Domain::GetAllUserProfiles
  lev_routine

  uses_routine LegacyUser::GetAllUserProfiles, translations: {outputs: {type: :verbatim}}

  protected

  def exec
    run(LegacyUser::GetAllUserProfiles)
  end
end
