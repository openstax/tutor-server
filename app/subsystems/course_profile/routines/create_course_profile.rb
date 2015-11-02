class CourseProfile::Routines::CreateCourseProfile
  lev_routine

  protected
  def exec(attrs = {})
    profile = CourseProfile::Models::Profile.new(attrs)
    GenerateToken.apply!(record: profile, attribute: :registration_token)
    outputs.profile = profile
  end
end
