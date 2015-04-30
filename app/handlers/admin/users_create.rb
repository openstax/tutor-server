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
                         openstax_uid: user_params[:openstax_uid],
                         access_token: user_params[:access_token],
                         first_name: user_params[:first_name],
                         last_name: user_params[:last_name],
                         full_name: user_params[:full_name],
                         title: user_params[:title],
                         entity_user_id: user_params[:entity_user_id],
                         account_id: user_params[:account_id],
                         exchange_identifier: user_params[:exchange_identifier])
  end
end
