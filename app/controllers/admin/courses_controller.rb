class Admin::CoursesController < Admin::BaseController
  include Manager::CourseDetails
  include Lev::HandleWith

  before_action :get_schools, only: [:new, :edit]
  before_action :get_catalog_offerings, only: [:new, :edit]

  def index
    courses = SearchCourses[query: params[:q]]
    @course_infos = CollectCourseInfo[courses: courses, with: :teacher_names]
  end

  def new
    @profile = CourseProfile::Models::Profile.new
  end

  def create
    handle_with(Admin::CoursesCreate,
                complete: -> (*) {
                  flash[:notice] = 'The course has been created.'
                  redirect_to admin_courses_path
                })
  end

  def edit
    get_course_details
  end

  def update
    handle_with(Admin::CoursesUpdate,
                params: course_params,
                complete: -> (*) {
                  flash[:notice] = 'The course has been updated.'
                  redirect_to admin_courses_path
                })
  end

  def students
    handle_with(Admin::CoursesStudents, success: -> {
      flash[:notice] = 'Student roster has been uploaded.'
    },
    failure: -> {
      flash[:error] = ['Error uploading student roster'] +
                        @handler_result.errors.collect(&:message).flatten

    })

    redirect_to edit_admin_course_path(params[:id], anchor: 'roster')
  end

  def set_ecosystem
    if params[:ecosystem_id].blank?
      flash[:error] = 'Please select a course ecosystem'
    else
      course = Entity::Course.find(params[:id])
      ecosystem = ::Content::Ecosystem.find(params[:ecosystem_id])

      if GetCourseEcosystem[course: course] == ecosystem
        flash[:notice] = "Course ecosystem \"#{ecosystem.title}\" is already selected for \"#{course.profile.name}\""
      else
        begin
          CourseContent::AddEcosystemToCourse[course: course, ecosystem: ecosystem]
          flash[:notice] = "Course ecosystem \"#{ecosystem.title}\" selected for \"#{course.profile.name}\""
        rescue Content::MapInvalidError => e
          flash[:error] = e.message
        end
      end
    end

    redirect_to edit_admin_course_path(params[:id], anchor: 'content')
  end

  private

  def course_params
    { id: params[:id], course: params.require(:course)
                                     .permit(:name,
                                             :appearance_code,
                                             :school_district_school_id,
                                             :catalog_offering_id,
                                             :is_concept_coach,
                                             teacher_ids: []) }
  end

  def get_schools
    @schools = SchoolDistrict::ListSchools[]
  end

  def get_catalog_offerings
    @catalog_offerings = Catalog::ListOfferings[]
  end
end
