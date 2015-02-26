class Domain::FindOrCreateUserForLegacyUser
  lev_routine

  uses_routine LegacyUser::FindOrCreateUserForLegacyUser,
               translations: {outputs: {type: :verbatim}}
  protected

  def exec(legacy_user)
    run(LegacyUser::FindOrCreateUserForLegacyUser, legacy_user)
  end
end
