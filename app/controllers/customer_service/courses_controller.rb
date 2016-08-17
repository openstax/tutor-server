class CustomerService::CoursesController < CustomerService::BaseController
  include Manager::CourseDetails

  before_action :get_schools, only: [:new, :edit]

  def index
    @query = params[:query]
    params_for_pagination = {page: params.fetch(:page, 1), per_page: params.fetch(:per_page, 25)}
    courses = SearchCourses[query: @query, order_by: params[:order_by]].try(:paginate, params_for_pagination)
    @total_courses = courses.try(:count)
    @course_infos = CollectCourseInfo[courses: courses,
                                      with: [:teacher_names, :ecosystem_book]]
  end

  def show
    get_course_details
  end

  private

  def get_schools
    @schools = SchoolDistrict::ListSchools[]
  end
end
