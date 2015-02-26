class Domain::CreateUser
  lev_routine

  uses_routine Entity::CreateUser, translations: {type: :verbatim}

  def exec
    result = run(Entity::CreateUser)
    fatal_error(code: :could_not_create_user) if result.errors.any?

    outputs[:user] = result.outputs.user
  end
end
