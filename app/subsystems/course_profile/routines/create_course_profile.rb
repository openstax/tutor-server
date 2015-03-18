class CourseProfile::CreateCourseProfile
  lev_routine

  protected
  def exec(attrs = {})
    outputs[:profile] = CourseProfile::Profile.create(attrs)
  end
end
