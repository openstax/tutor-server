class Domain::CreateCourse
  lev_routine

  uses_routine Entity::CreateCourse, translations: {outputs: {type: :verbatim}}

  def exec(name: 'Unnamed')
    run(Entity::CreateCourse)
    # TODO for JoeSMak (soon) running some CourseProfile routine to create profile and set the name
  end
end
