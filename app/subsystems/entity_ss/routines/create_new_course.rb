class EntitySs::CreateNewCourse
  lev_routine

  protected

  def exec
    course = EntitySs::Course.create
    transfer_errors_from(course, {type: :verbatim}, true)
    outputs[:course] = course
  end
end
