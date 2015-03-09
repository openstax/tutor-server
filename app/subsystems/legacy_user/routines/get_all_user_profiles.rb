class LegacyUser::GetAllUserProfiles
  lev_routine

  protected

  def exec
    outputs[:profiles] = User.includes(:account).find_each.collect do |legacy_user|
      entity_user = LegacyUser::FindOrCreateUserForLegacyUser.call(legacy_user).outputs.user
      {
        legacy_user_id: legacy_user.id,
        entity_user_id: entity_user.id,
        full_name:      legacy_user.account.full_name
      }
    end
  end
end
