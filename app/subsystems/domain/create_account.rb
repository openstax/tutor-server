class Domain::CreateAccount
  lev_routine

  protected

  def exec(user_params)
    outputs[:account] = OpenStax::Accounts.create_temp_user(
      username: user_params.username,
      password: user_params.password
    )
  end
end
