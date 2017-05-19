class CourseProfile::BuildPreviewCourses
  lev_routine

  uses_routine ::CreateCourse, translations: { outputs: { type: :verbatim } },
               as: :create_course

  protected

  def exec(desired_count: Settings::Db.store.prebuilt_preview_course_count)

    while (
      offerings = self.class.offerings_that_need_previews(desired_count: desired_count).to_a
    ).any?
      term = TermYear.visible_term_years.first

      offerings.each do |offering|
        (desired_count - offering.course_preview_count).times do

          run(:create_course, {
                name: "#{offering.description} Preview",
                term: term.term,
                year: term.year,
                is_preview: true,
                is_college: true,
                num_sections: 2,
                time_zone: "Central Time (US & Canada)",
                catalog_offering: offering
              })
          outputs.course.update_attributes(is_preview_claimed: false)
        end
      end
    end

  end

  def self.offerings_that_need_previews(desired_count: Settings::Db.store.prebuilt_preview_course_count)
    courses = CourseProfile::Models::Course
                .where("is_preview = 't' and is_preview_claimed = 'f'")
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
  end


end
