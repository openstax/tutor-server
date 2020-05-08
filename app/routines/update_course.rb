class UpdateCourse
  lev_routine

  uses_routine CourseProfile::UpdateCourse, as: :update_course

  protected

  def exec(id, params)
    run(:update_course, id, params)
  end
end
