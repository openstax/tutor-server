class CourseProfile::Routines::CreateCourseProfile
  lev_routine

  protected
  def exec(attrs = {})
    attrs[:is_concept_coach] = false if attrs[:is_concept_coach].nil?
    outputs.profile = CourseProfile::Models::Profile.create(attrs)
  end
end
