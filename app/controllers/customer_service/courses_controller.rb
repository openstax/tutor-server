class CustomerService::CoursesController < CustomerService::BaseController
  before_action :get_schools, only: [:new, :edit]

  def index
    @courses = CollectCourseInfo[with: :teacher_names]
  end

  def show
    get_course_details
  end

  private

  def get_schools
    @schools = SchoolDistrict::ListSchools[]
  end

  def get_course_details
    entity_course = Entity::Course.find(params[:id])
    @course = GetCourseProfile[course: entity_course]
    @periods = entity_course.periods
    @teachers = entity_course.teachers.includes(role: { profile: :account })
    @ecosystems = Content::ListEcosystems[]

    @course_ecosystem = nil
    ecosystem_model = entity_course.ecosystems.first
    return if ecosystem_model.nil?

    ecosystem_strategy = ::Content::Strategies::Direct::Ecosystem.new(ecosystem_model)
    @course_ecosystem = ::Content::Ecosystem.new(strategy: ecosystem_strategy)
  end
end
