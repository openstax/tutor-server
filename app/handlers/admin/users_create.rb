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
    user_params = params[:user]
    run(:create_profile, username: user_params[:username],
                         password: user_params[:password])
  end
end
