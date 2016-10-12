class CourseProfile::SetCatalogOffering

  lev_routine

  protected

  def exec(entity_course:, catalog_offering:)
    profile = CourseProfile::Models::Profile.find_by(entity_course_id: entity_course.id)
    profile.update_attribute :catalog_offering_id, catalog_offering.id
  end

end
