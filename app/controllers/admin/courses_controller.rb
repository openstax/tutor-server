class Admin::CoursesController < Admin::BaseController
  def index
    @courses = Domain::ListCourses.call.outputs.courses
  end

  def create
    handle_with(Admin::CoursesCreate,
                complete: -> (*) {
                  flash[:notice] = 'The course has been created.'
                  redirect_to admin_courses_path
                })
  end
end
