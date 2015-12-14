class CourseProfile::Routines::CreateCourseProfile
  lev_routine outputs: { profile: :_self }

  protected
  def exec(attrs = {})
    attrs[:is_concept_coach] = false if attrs[:is_concept_coach].nil?
    set(profile: CourseProfile::Models::Profile.create(attrs))
  end
end
