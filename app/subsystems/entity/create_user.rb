class Entity::CreateUser
  lev_routine

  protected

  def exec
    user = Entity::Models::User.create
    transfer_errors_from(user, {type: :verbatim}, true)
    outputs[:user] = user
  end
end
