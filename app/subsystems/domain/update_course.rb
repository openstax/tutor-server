class Domain::UpdateCourse
  lev_routine

  uses_routine CourseProfile::Api::UpdateProfile, as: :update_profile

  protected

  def exec(id, course_params)
    run(:update_profile, id, course_params)
  end

end
