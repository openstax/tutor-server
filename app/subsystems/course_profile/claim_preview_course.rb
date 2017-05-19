class CourseProfile::ClaimPreviewCourse
  lev_routine express_output: :course

  protected

  def exec(catalog_offering:, name:)
    course = CourseProfile::Models::Course
               .where(is_preview: true,
                      preview_claimed_at: nil,
                      catalog_offering_id: catalog_offering.id)
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

    offset = (Time.now - course.created_at).seconds.to_i
    update = lambda { |fields|
      return fields.map{|f| "#{f} = #{f} + interval '#{offset} seconds'"}.join(', ')
    }

    CourseProfile::Models::Course
      .where({id: course.id})
      .update_all(update[%w{created_at updated_at}])

    course.taskings.update_all(update[%w{created_at updated_at}])

    tasks = Tasks::Models::Task
              .joins(taskings: :period )
              .where(taskings: { period: { course_profile_course_id: course.id } })

    tasks.update_all(
      update[%w{opens_at_ntz due_at_ntz feedback_at_ntz last_worked_at created_at updated_at deleted_at}]
    )

    outputs.course = course.reload
  end
end
