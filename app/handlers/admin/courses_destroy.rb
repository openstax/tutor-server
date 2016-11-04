class Admin::CoursesDestroy
  lev_handler

  protected

  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    course = CourseProfile::Models::Course.find(params[:id])

    fatal_error(code: :course_not_empty, message: 'Can only delete completely empty courses') \
      unless course.deletable?

    course.destroy!
  end
end
