class Domain::CreateCourse
  lev_routine

  uses_routine Entity::CreateCourse, translations: {outputs: {type: :verbatim}}

  def exec
    run(Entity::CreateCourse)
  end
end
