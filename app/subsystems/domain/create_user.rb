class Domain::CreateUser
  lev_routine

  uses_routine Entity::CreateUser, translations: {outputs: {type: :verbatim}}

  def exec
    run(Entity::CreateUser)
  end
end
