class CourseProfile::ClaimPreviewCourse
  lev_routine express_output: :course

  protected

  def exec(catalog_offering:, name:)
    course = CourseProfile::Models::Course
               .where(is_preview: true,
                      preview_claimed_at: nil,
                      catalog_offering_id: catalog_offering.id)
               .lock
               .first
    if course.nil?
      fatal_error(code: :no_preview_courses_available)
      return
    end

    current_term = TermYear.visible_term_years.first
    course.update_attributes(
      name: name,
      preview_claimed_at: Time.now,
      starts_at: current_term.starts_at,
      ends_at: current_term.ends_at
    )

    interval = "interval '#{(Time.now - course.created_at).seconds.to_i} seconds'"
    update = lambda { |fields|
      return fields.map{|f| "#{f} = #{f} + #{interval}"}.join(', ')
    }

    tasks = Tasks::Models::Task
              .joins(taskings: :period )
              .where(taskings: { period: { course_profile_course_id: course.id } })
    tasks.update_all(
      update[%w{opens_at_ntz due_at_ntz feedback_at_ntz last_worked_at}]
    )
    course.taskings.reset
    outputs.course = course
  end
end
