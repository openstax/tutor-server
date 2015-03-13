class Domain::FindOrCreateUser
  lev_routine

  uses_routine UserProfile::FindOrCreate,
               translations: {outputs: {type: :verbatim}}
  protected

  def exec(legacy_user)
    run(UserProfile::FindOrCreate, legacy_user)
  end
end
