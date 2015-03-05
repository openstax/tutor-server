class Admin::CoursesUpdate
  lev_handler

  uses_routine Domain::UpdateCourse, as: :update_course

  protected

  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    run(:update_course, params[:id], params[:course])
  end
end
