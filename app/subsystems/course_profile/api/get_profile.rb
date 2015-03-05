class CourseProfile::Api::GetProfile
  lev_routine

  protected

  def exec(entity_course_id)
    profile = CourseProfile::Profile.find_by(entity_course_id: entity_course_id)
    outputs[:profile] = {}
    outputs[:profile][:course_id] = profile.entity_course_id
    outputs[:profile][:name] = profile.name
  end
end
