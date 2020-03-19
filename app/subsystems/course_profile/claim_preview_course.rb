class CourseProfile::ClaimPreviewCourse

  lev_routine express_output: :course

  protected

  def exec(catalog_offering:, name:, current_time: Time.current)
    course = CourseProfile::Models::Course
               .lock
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
               .where(
                 is_preview: true,
                 is_preview_ready: true,
                 preview_claimed_at: nil,
                 catalog_offering_id: catalog_offering.id
               )
               .reorder(
                 Arel.sql(
                   ActiveRecord::Base.sanitize_sql_array(
                     [
                       '"initial_course_ecosystem"."content_ecosystem_id" = ? DESC',
                       catalog_offering.content_ecosystem_id
                     ]
                   )
                 )
               )
               .first
    if course.nil?
      WarningMailer.log_and_deliver(
        "Failed to claim preview course for offering id #{catalog_offering.id}"
      )

      fatal_error(code: :no_preview_courses_available)
    end

    year = current_time.year
    term_year = TermYear.new(:preview, year)
    course.update_attributes(
      name: name,
      preview_claimed_at: current_time,
      term: :preview,
      year: year,
      starts_at: term_year.starts_at,
      ends_at: term_year.ends_at
    )

    interval = "interval '#{(current_time - course.created_at).seconds.to_i} seconds'"
    update = ->(fields) do
      fields.map { |field| "\"#{field}\" = \"#{field}\" + #{interval}" }.join(', ')
    end

    tasking_plans = Tasks::Models::TaskingPlan.joins(:task_plan).where(task_plan: { owner: course })
    tasking_plans.update_all( update[%w{opens_at_ntz due_at_ntz}] )
    tasks = Tasks::Models::Task
              .joins(taskings: :period )
              .where(taskings: { period: { course_profile_course_id: course.id } })
    tasks.update_all( update[%w{opens_at_ntz due_at_ntz feedback_at_ntz last_worked_at}] )

    course.taskings.reset

    outputs.course = course
  end

end
