class CourseProfile::BuildPreviewCourses

  lev_routine transaction: :no_transaction

  # We really want no transaction here, so we don't call uses_routine
  # uses_routine ::CreateCourse, as: :create_course
  # uses_routine PopulatePreviewCourseContent, as: :populate_preview_course_content

  protected

  def exec(desired_count: Settings::Db.store.prebuilt_preview_course_count)
    loop do
      # Start a transaction for every course created so we don't lose work in case of a crash
      CourseProfile::Models::Course.transaction do
        # We need to call this in every transaction so we lock the offering
        offering = offering_that_needs_previews(desired_count)
        return if offering.nil? # No more work to do

        course = ::CreateCourse[
          name: "#{offering.description} Preview",
          is_preview: true,
          is_college: true,
          num_sections: 2,
          time_zone: "Central Time (US & Canada)",
          catalog_offering: offering
        ]

        PopulatePreviewCourseContent[course: course]
      end
    end
  end

  def offering_that_needs_previews(desired_count)
    courses = CourseProfile::Models::Course
                .where(is_preview: true, preview_claimed_at: nil)
                .group(:catalog_offering_id)
                .select([:catalog_offering_id, 'count(*) as course_preview_count'])

    # We only lock one offering here, so other calls to this routine
    # could potentially work on different offerings simultaneously
    Catalog::Models::Offering
      .joins do
        courses.as('course_preview_counts')
               .on { id == course_preview_counts.catalog_offering_id }
               .outer
      end
      .where(is_tutor: true, is_available: true)
      .where(['coalesce(course_preview_count, 0) < ?', desired_count])
      .select('coalesce(course_preview_count, 0) as course_preview_count, catalog_offerings.*')
      .reorder(1, :number) # Work on offerings with lower course_preview_count first
      .lock('FOR NO KEY UPDATE OF catalog_offerings SKIP LOCKED') # Skip offerings being worked on
      .first # Only lock 1 offering at a time
  end

end
