class Admin::CoursesController < Admin::BaseController
  before_action :get_users, only: [:new, :edit]

  def index
    @courses = ListCourses.call(with: :teacher_names).outputs.courses
  end

  def create
    handle_with(Admin::CoursesCreate,
                complete: -> (*) {
                  flash[:notice] = 'The course has been created.'
                  redirect_to admin_courses_path
                })
  end

  def edit
    entity_course = Entity::Course.find(params[:id])
    @course = GetCourse[course: entity_course]
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
    { id: params[:id], course: params.require(:course)
                                     .permit(:name, teacher_ids: []) }
  end

  def get_users
    @users = GetAllUserProfiles[]
  end
end
