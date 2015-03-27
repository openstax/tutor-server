class UserProfile::FindOrCreate
  lev_routine

  uses_routine Entity::CreateUser

  protected

  def exec(attributes)
    outputs[:profile] = UserProfile::Models::Profile.create(attributes)
    outputs[:user] = outputs[:profile].entity_user
  end
end
