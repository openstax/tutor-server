class Domain::CreateCourse
  lev_routine

  uses_routine Entity::CreateCourse, translations: {type: :verbatim}

  def exec
    result = run(Entity::CreateCourse)
    fatal_error(code: :could_not_create_course) if result.errors.any?

    outputs[:course] = result.outputs.course
  end
end
