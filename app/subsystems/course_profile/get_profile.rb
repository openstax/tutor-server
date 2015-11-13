class CourseProfile::GetProfile
  lev_routine express_output: :profile

  protected
  def exec(course: nil, attrs: {})
    profile = course ? get_profile_by_course(course) : get_profile_by_attrs(attrs)

    outputs.profile = {
      course_id: profile.entity_course_id,
      catalog_offering_identifier: profile.catalog_offering_identifier,
      name: profile.name
    }
  end

  private
  def get_profile_by_course(course)
    get_profile_by_attrs(entity_course_id: course.id)
  end

  def get_profile_by_attrs(attrs)
    CourseProfile::Models::Profile.find_by(attrs) || fatal_error(code: :profile_not_found)
  end
end
