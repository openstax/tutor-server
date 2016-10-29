class CourseProfile::CreateCourse
  lev_routine

  protected
  def exec(attrs = {})
    outputs.course = CourseProfile::Models::Course.create(attrs)
    transfer_errors_from outputs.course, {type: :verbatim}, true
  end
end
