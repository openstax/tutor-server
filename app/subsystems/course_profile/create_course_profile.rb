class CourseProfile::CreateCourseProfile
  lev_routine

  protected
  def exec(attrs = {})
    outputs.profile = CourseProfile::Models::Profile.create(attrs)
    transfer_errors_from outputs.profile, {type: :verbatim}, true
  end
end
