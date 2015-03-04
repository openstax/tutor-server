class Domain::CreateCourse
  lev_routine

  uses_routine Entity::CreateCourse, translations: {outputs: {type: :verbatim}}

  def exec(name: 'Unnamed')
    run(Entity::CreateCourse)
    run(CourseProfile::CreateCourseProfile, name: name, course: outputs.course)
  end
end
