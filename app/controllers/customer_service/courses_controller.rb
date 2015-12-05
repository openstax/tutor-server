class CustomerService::CoursesController < CustomerService::BaseController
  include Manager::CourseDetails

  before_action :get_schools, only: [:new, :edit]

  def index
    @query = params[:query]
    courses = SearchCourses[query: @query]
    @course_infos = CollectCourseInfo[courses: courses, with: :teacher_names]
  end

  def show
    get_course_details
  end

  private

  def get_schools
    @schools = SchoolDistrict::ListSchools[]
  end
end
