class UserProfile::CreateProfile
  lev_routine

  protected

  def exec(attributes)
    outputs[:profile] = UserProfile::Profile.create(attributes)
    outputs[:user] = outputs[:profile].entity_user
  end
end
