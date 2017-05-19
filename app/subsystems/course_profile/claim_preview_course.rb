class CourseProfile::ClaimPreviewCourse
  lev_routine express_output: :course

  protected

  def exec(catalog_offering:, name:)
    outputs.course = CourseProfile::Models::Course
                       .where(is_preview: true,
                              preview_claimed_at: nil,
                              catalog_offering_id: catalog_offering.id)
                       .first
    if outputs.course.nil?
      fatal_error(code: :no_preview_courses_available)
      return
    end

    outputs.course.update_attributes(
      name: name,
      preview_claimed_at: Time.now
    )
  end
end
