class CustomerService::CoursesController < CustomerService::BaseController
  include Manager::CourseDetails

  before_action :get_schools, only: [:new, :edit]

  def index
    @query = params[:query]
    @order_by = params[:order_by]
    courses = SearchCourses.call(query: params[:query], order_by: params[:order_by]).outputs
    params[:per_page] = courses.total_count if params[:per_page] == "all"
    @total_courses = courses.total_count
    @course_infos = courses.items.preload(
      [
        { teachers: { role: [:role_user, :profile] },
          periods: :students,
          course_ecosystems: { ecosystem: :books } },
        :periods
      ]
    ).paginate(page: params.fetch(:page, 1), per_page: params.fetch(:per_page, 25))
  end

  def show
    get_course_details
  end

  private

  def get_schools
    @schools = SchoolDistrict::ListSchools[]
  end
end
