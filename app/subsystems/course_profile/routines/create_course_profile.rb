class CourseProfile::Routines::CreateCourseProfile
  lev_routine

  protected
  def exec(attrs = {})
    outputs.profile = CourseProfile::Models::Profile.create(attrs)
  end
end
