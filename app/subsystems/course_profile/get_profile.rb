class CourseProfile::GetProfile
  lev_routine express_output: :profile

  protected
  def exec(course: nil, attrs: {})
    profile = course ? get_profile_by_course(course) : get_profile_by_attrs(attrs)
    offering = Catalog::GetOffering[id: profile.catalog_offering_id]

    outputs.profile = {
      course_id: profile.entity_course_id,
      name: profile.name,
      catalog_offering_id: offering.try(:id),
      salesforce_book_name: offering.try(:salesforce_book_name),
      appearance_code: offering.try(:appearance_code),
      is_concept_coach: profile.is_concept_coach
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
