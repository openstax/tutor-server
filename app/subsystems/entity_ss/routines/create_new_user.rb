class EntitySs::CreateNewUser
  lev_routine

  protected

  def exec
    user = EntitySs::User.create
    transfer_errors_from(user, {type: :verbatim}, true)
    outputs[:user] = user
  end
end
