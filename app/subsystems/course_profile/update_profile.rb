class CourseProfile::UpdateProfile
  lev_routine

  protected

  def exec(id, course_params)
    profile = CourseProfile::Models::Profile.find_by(entity_course_id: id)
    profile.update_attributes(course_params)
  end
end
