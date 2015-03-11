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

  def edit
    @course = Domain::GetCourse.call(params[:id]).outputs.course
  end

  def update
    handle_with(Admin::CoursesUpdate,
                params: course_params,
                complete: -> (*) {
                  flash[:notice] = 'The course has been updated.'
                  redirect_to admin_courses_path
                })
  end

  private
  def course_params
    { id: params[:id], course: params.require(:course).permit(:name) }
  end
end
