class Admin::CoursesController < Admin::BaseController
  include Manager::CourseDetails
  include Lev::HandleWith

  before_action :get_schools, only: [:new, :edit]

  def index
    @courses = CollectCourseInfo[with: :teacher_names]
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
      add_students(@handler_result.outputs.period,
                   @handler_result.outputs.users_attributes)
      flash[:notice] = 'Student roster has been uploaded.'
      redirect_to edit_admin_course_path(params[:id], anchor: 'roster')
    },
    failure: -> {
      flash[:error] = @handler_result.errors.collect(&:message).compact
      redirect_to edit_admin_course_path(params[:id], anchor: 'roster')
    })
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

  def set_catalog_offering
    identifier = params[:catalog_offering_identifier]
    if identifier.blank?
      flash[:error] = 'Please select a catalog identifier'
    else
      course = Entity::Course.find(params[:id])
      CourseProfile::SetCatalogIdentifier[ entity_course: course, identifier: identifier ]
      flash[:notice] = "Catalog offering identifier \"#{identifier}\" selected for \"#{course.name}\""
    end
    redirect_to edit_admin_course_path(params[:id], anchor: 'content')
  end

  private

  def course_params
    { id: params[:id], course: params.require(:course)
                                     .permit(:name,
                                             :school_district_school_id,
                                             teacher_ids: []) }
  end

  def get_schools
    @schools = SchoolDistrict::ListSchools[]
  end

  def add_students(period, users_attributes)
    users_attributes.each do |user_attributes|
      user = find_or_create(user_attributes)
      AddUserAsPeriodStudent.call(period: period, user: user)
    end
  end

  def find_or_create(user)
    username = user['username']
    first_name = user['first_name']
    last_name = user['last_name']
    User::FindOrCreateUser[username: user['username'],
                           password: user['password'],
                           first_name: first_name,
                           last_name: last_name]
  end
end
