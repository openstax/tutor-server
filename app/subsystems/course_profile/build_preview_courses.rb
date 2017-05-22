class CourseProfile::BuildPreviewCourses
  lev_routine

  uses_routine ::CreateCourse, as: :create_course
  uses_routine PopulatePreviewCourseContent, as: :populate_preview_course_content

  protected

  def exec(desired_count: Settings::Db.store.prebuilt_preview_course_count)
    while (
      offerings = offerings_that_need_previews(desired_count)
    ).any?
      term = TermYear.visible_term_years.first

      offerings.each do |offering|
        (desired_count - offering.course_preview_count).times do

          course = run(:create_course, {
                name: "#{offering.description} Preview",
                term: term.term,
                year: term.year,
                is_preview: true,
                is_college: true,
                num_sections: 2,
                time_zone: "Central Time (US & Canada)",
                catalog_offering: offering
              }).outputs.course

          run(:populate_preview_course_content, course: course)
        end
      end
    end
  end


  def self.run_scheduled_build
    CourseProfile::Models::Course.transaction do
      CourseProfile::Models::Course.with_advisory_lock('preview-builder', 0) do
        self.call
      end
    end
  end


  def offerings_that_need_previews(desired_count)
    courses = CourseProfile::Models::Course
                .where("is_preview = 't' and preview_claimed_at is null")
                .group(:catalog_offering_id)
                .select([:catalog_offering_id, 'count(*) as course_preview_count'])

    Catalog::Models::Offering
      .joins { courses.as('course_preview_counts')
                 .on { id == course_preview_counts.catalog_offering_id }
                 .outer }
      .where(
        ["is_tutor = 't' and is_available = 't' and " \
         'coalesce(course_preview_count, 0) < ?', desired_count]
      )
      .select(
        'catalog_offerings.*, coalesce(course_preview_count, 0) as course_preview_count'
      )
      .to_a
  end


end
