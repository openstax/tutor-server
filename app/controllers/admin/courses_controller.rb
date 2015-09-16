class Admin::CoursesController < Admin::BaseController
  before_action :get_schools, except: [:index, :destroy, :students]

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
    entity_course = Entity::Course.find(params[:id])
    @course = GetCourseProfile[course: entity_course]
    @periods = entity_course.periods
    @teachers = entity_course.teachers.includes(role: { user: { profile: :account } })
    @ecosystems = Content::ListEcosystems[]

    @course_ecosystem = nil
    ecosystem_model = entity_course.ecosystems.first
    return if ecosystem_model.nil?

    ecosystem_strategy = ::Content::Strategies::Direct::Ecosystem.new(ecosystem_model)
    @course_ecosystem = ::Content::Ecosystem.new(strategy: ecosystem_strategy)
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
    # Upload a csv file with columns: first_name, last_name, username, password
    period = CourseMembership::Models::Period.find(params[:course][:period])
    roster_file = params[:student_roster]

    begin
      csv_reader = CSV.new(roster_file.read, headers: true)
      users = []
      errors = []
      csv_reader.each do |row|
        users << row
        errors << "On line #{csv_reader.lineno}, username is missing." unless row['username'].present?
        errors << "On line #{csv_reader.lineno}, password is missing." unless row['password'].present?
      end
      if errors.present?
        flash[:error] = ['Error uploading student roster'] + errors
      else
        add_students(period, users)
        flash[:notice] = 'Student roster has been uploaded.'
      end
    rescue CSV::MalformedCSVError => e
      flash[:error] = e.message
    end

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

  def export_activity
    @course = Entity::Course.find(params[:id])
    formatted_name = @course.name.downcase.gsub(' ', '_')
    formatted_time = Time.current.strftime('%Y-%m-%d-%H-%M-%S-%L')
      # year - month - day - 24-hour clock hour - minute - second - millisecond
    @filepath = "/admin/exports/#{formatted_name}_#{formatted_time}.csv"
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

  def add_students(period, users)
    users.each do |user|
      profile = find_or_create(user)
      AddUserAsPeriodStudent.call(period: period, user: profile.entity_user)
    end
  end

  def find_or_create(user)
    username = user['username']
    first_name = user['first_name']
    last_name = user['last_name']
    UserProfile::FindOrCreateProfile[username: user['username'],
                                     password: user['password'],
                                     first_name: first_name,
                                     last_name: last_name]
  end
end
