class CourseProfile::CreateCourseProfile
  lev_routine

  protected
  def exec(attrs = {})
    CourseProfile::Profile.create(attrs)
  end
end
