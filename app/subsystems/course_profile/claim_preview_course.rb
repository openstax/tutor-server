class CourseProfile::ClaimPreviewCourse
  lev_routine express_output: :course

  protected

  def exec(catalog_offering:, name:, current_time: Time.current)
    course = CourseProfile::Models::Course.lock.find_by(
      is_preview: true,
      is_preview_ready: true,
      preview_claimed_at: nil,
      catalog_offering_id: catalog_offering.id
    )
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
    tasking_plans.update_all update[%w{opens_at_ntz due_at_ntz closes_at_ntz}]
    tasks = Tasks::Models::Task.joins(taskings: :period ).where(
      taskings: { period: { course_profile_course_id: course.id } }
    )
    tasks.update_all update[%w{opens_at_ntz due_at_ntz closes_at_ntz last_worked_at}]

    course.taskings.reset

    outputs.course = course
  end
end
