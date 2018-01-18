class UpdateCourse
  lev_routine

  uses_routine CourseProfile::UpdateCourse, as: :update_course

  protected

  def exec(id, params)
    course_params = params.except(:time_zone)
    run(:update_course, id, course_params)

    return unless params[:time_zone]

    time_zone = ::TimeZone.joins(:course).find_by(course: { id: id })
    time_zone.name = params[:time_zone]
    fatal_error(code: :invalid_time_zone) unless time_zone.save
  end

end
