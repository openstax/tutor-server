class CourseProfile::SetCatalogIdentifier

  lev_routine

  protected

  def exec(entity_course:, catalog_offering_id:)
    profile = CourseProfile::Models::Profile.find_by(entity_course_id: entity_course.id)
    profile.update_attributes!(catalog_offering_id: catalog_offering_id)
  end

end
