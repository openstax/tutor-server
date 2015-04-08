class CreateUserProfile
  lev_routine

  uses_routine UserProfile::CreateProfile,
    as: :create_user_profile

  protected

  def exec(attributes = {})
    run(:create_user_profile, attributes)
  end
end
