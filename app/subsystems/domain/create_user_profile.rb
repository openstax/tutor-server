class Domain::CreateUserProfile
  lev_routine

  uses_routine UserProfile::FindOrCreate,
    as: :create_user_profile

  protected

  def exec(attributes = {})
    run(:create_user_profile, attributes)
  end
end
