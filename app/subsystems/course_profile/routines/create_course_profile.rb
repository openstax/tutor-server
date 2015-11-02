class CourseProfile::Routines::CreateCourseProfile
  lev_routine

  protected
  def exec(attrs = {})
    profile = CourseProfile::Models::Profile.new(attrs)
    GenerateToken.apply!(record: profile, attribute: :teacher_access_token)
    outputs.profile = profile
  end
end
