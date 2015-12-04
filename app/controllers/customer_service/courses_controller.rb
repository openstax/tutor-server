class CustomerService::CoursesController < CustomerService::BaseController
  include Manager::CourseDetails

  before_action :get_schools, only: [:new, :edit]

  def index
    courses = SearchCourses[query: params[:q]]
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
