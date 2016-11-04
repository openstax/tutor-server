class UpdateCourse
  lev_routine

  uses_routine CourseProfile::UpdateCourse, as: :update_course

  protected

  def exec(id, params)
    course_params = params.except(:time_zone)
    run(:update_course, id, course_params)

    return unless params[:time_zone]

    ::TimeZone.joins(:course).where(course: {id: id}).update_all(name: params[:time_zone])
  end

end
