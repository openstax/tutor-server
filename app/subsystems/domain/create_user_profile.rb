class Domain::CreateUserProfile
  lev_routine

  uses_routine UserProfile::CreateUser

  protected

  def exec(attributes = {})
    run(UserProfile::FindOrCreate, attributes)
  end
end
