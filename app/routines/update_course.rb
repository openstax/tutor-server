class UpdateCourse
  lev_routine

  uses_routine CourseProfile::UpdateProfile, as: :update_profile

  protected

  def exec(id, params)
    course_params = params.except(:time_zone)
    run(:update_profile, id, course_params)

    return unless params[:time_zone]

    ::TimeZone.joins(profile: :course).where(profile: {course: {id: id}})
                                      .update_all(name: params[:time_zone])
  end

end
