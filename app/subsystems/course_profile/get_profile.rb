class CourseProfile::GetProfile
  lev_routine outputs: { profile: :_self }

  protected
  def exec(course: nil, attrs: {})
    profile = course ? get_profile_by_course(course) : get_profile_by_attrs(attrs)
    set(profile: profile)
  end

  private
  def get_profile_by_course(course)
    get_profile_by_attrs(entity_course_id: course.id)
  end

  def get_profile_by_attrs(attrs)
    CourseProfile::Models::Profile.find_by(attrs) || fatal_error(code: :profile_not_found)
  end
end
