class CourseProfile::GetProfile
  lev_routine

  protected

  def exec(entity_course_id)
    profile = CourseProfile::Models::Profile.find_by(entity_course_id: entity_course_id)
    outputs[:profile] = {
      course_id: profile.entity_course_id,
      name: profile.name
    }
  end
end
