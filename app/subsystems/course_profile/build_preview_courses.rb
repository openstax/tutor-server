class CourseProfile::BuildPreviewCourses
  lev_routine transaction: :no_transaction

  # We really want no transaction here, so we don't call uses_routine
  # uses_routine ::CreateCourse
  # uses_routine PopulatePreviewCourseContent

  protected

  def log(level, &block)
    Rails.logger.tagged(self.class.name) { |logger| logger.public_send(level, &block) }
  end

  def exec(desired_count: Settings::Db.prebuilt_preview_course_count)
    start_time = Time.current
    log(:debug) { "Started at #{start_time}" }

    created_course_counts_by_offering_title = Hash.new { |hash, key| hash[key] = 0 }
    lowest_preview_counts_by_offering_title = Hash.new { |hash, key| hash[key] = desired_count }
    loop do
      # Start a transaction for every course created so we don't lose work in case of a crash
      course = CourseProfile::Models::Course.transaction do
        # We need to call this in every transaction so we lock the offering
        offering = offering_that_needs_previews(desired_count)
        if offering.nil?
          # No more work to do
          end_time = Time.current

          log(:info) do
            created_preview_courses_description = created_course_counts_by_offering_title
              .map do |offering_title, course_count|
              lowest = lowest_preview_counts_by_offering_title[offering_title]

              "#{course_count} preview course(s) for #{offering_title} (lowest count #{lowest})"
            end.join(', ')

            "Created #{created_preview_courses_description} in #{end_time - start_time} second(s)"
          end unless created_course_counts_by_offering_title.empty?

          log(:debug) { "Finished at #{end_time}" }

          return
        end

        ::CreateCourse[
          name: "#{offering.description} Preview",
          is_preview: true,
          is_test: false,
          is_college: true,
          num_sections: 2,
          timezone: 'US/Central',
          catalog_offering: offering
        ].tap do |course|
          offering_title = offering.title
          created_course_counts_by_offering_title[offering_title] += 1
          lowest_preview_counts_by_offering_title[offering_title] = [
            lowest_preview_counts_by_offering_title[offering_title], offering.preview_course_count
          ].min
        end
      end

      PopulatePreviewCourseContent.perform_later(course: course)
    end
  end

  def offering_that_needs_previews(desired_count)
    # is_preview_ready: false prevents the course from being claimed
    # but it still counts for the total here
    course_counts_sql = CourseProfile::Models::Course
      .select(
        :catalog_offering_id,
        'COUNT(*) as "preview_course_count"',
        '"initial_course_ecosystem"."content_ecosystem_id"'
      )
      .joins(
        <<~JOIN_SQL
          CROSS JOIN LATERAL (
            SELECT "course_content_course_ecosystems"."content_ecosystem_id"
            FROM "course_content_course_ecosystems"
            WHERE "course_content_course_ecosystems"."course_profile_course_id" =
              "course_profile_courses"."id"
            ORDER BY "course_content_course_ecosystems"."created_at"
            LIMIT 1
          ) AS "initial_course_ecosystem"
        JOIN_SQL
      )
      .where(is_preview: true, preview_claimed_at: nil)
      .group(:catalog_offering_id, '"initial_course_ecosystem"."content_ecosystem_id"')
      .to_sql

    of = Catalog::Models::Offering.arel_table
    cc = Arel::Table.new(:course_counts)
    preview_course_count = Arel::Nodes::NamedFunction.new(
      'COALESCE', [cc[:preview_course_count], 0]
    )

    # We only lock one offering here, so other calls to this routine
    # could potentially work on different offerings simultaneously
    Catalog::Models::Offering
      .without_deleted
      .select(of[Arel.star], preview_course_count.dup.as('"preview_course_count"'))
      .joins(
        <<-JOIN_SQL.strip_heredoc
          LEFT OUTER JOIN (#{course_counts_sql})
            AS "course_counts"
            ON #{cc[:catalog_offering_id].eq(of[:id]).to_sql}
              AND #{cc[:content_ecosystem_id].eq(of[:content_ecosystem_id]).to_sql}
        JOIN_SQL
      )
      .where(is_preview_available: true)
      .where(preview_course_count.lt(desired_count))
      .reorder(preview_course_count, :number)                       # Work on lower counts first
      .lock('FOR NO KEY UPDATE OF "catalog_offerings" SKIP LOCKED') # Skip offerings being worked on
      .first                                                        # Lock 1 offering at a time
  end
end
