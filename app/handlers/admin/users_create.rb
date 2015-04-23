class Admin::UsersCreate
  lev_handler

  uses_routine UserProfile::CreateProfile,
    translations: { outputs: { type: :verbatim } },
    as: :create_profile

  protected
  def authorized?
    true
  end

  def handle
    run(:create_profile, attrs: params[:user])
  end
end
