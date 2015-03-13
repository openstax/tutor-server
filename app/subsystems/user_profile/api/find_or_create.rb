class UserProfile::FindOrCreate
  lev_routine

  uses_routine Entity::CreateUser

  protected

  def exec(legacy_user)
    ss_map = UserProfile::User.includes(:entity_user).where{user_id == legacy_user.id}.first
    unless ss_map
      user = run(Entity::CreateUser).outputs.user
      ss_map = UserProfile::User.create(user_id: legacy_user.id, entity_user_id: user.id)
      transfer_errors_from(ss_map, {type: :verbatim}, true)
    end
    outputs[:user] = ss_map.entity_user
  end
end
