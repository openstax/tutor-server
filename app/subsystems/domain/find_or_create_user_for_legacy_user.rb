class Domain::FindOrCreateUserForLegacyUser
  lev_routine

  protected

  def exec(legacy_user)
    result = run(LegacyUser::FindOrCreateUserForLegacyUser, legacy_user)
    fatal_error(code: :could_not_find_or_create_user, offending_inputs: legacy_user) if result.errors.any?
    outputs[:user] = result.outputs.user
  end
end
