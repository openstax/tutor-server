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
    @course = GetCourseProfile[course: entity_course]
    @periods = entity_course.periods
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
    # Upload a csv file with columns: first_name, last_name, email, username.
    period = CourseMembership::Models::Period.find(params[:course][:period])
    roster_file = params[:student_roster]
    csv_reader = CSV.new(roster_file.read, headers: true)
    users = []
    errors = []
    csv_reader.each do |row|
      users << row
      errors << "On line #{csv_reader.lineno}, username is missing." unless row['username'].present?
      errors << "On line #{csv_reader.lineno}, email is missing." unless row['email'].present?
      errors << "On line #{csv_reader.lineno}, username #{row['username']} has already been taken." \
        if row['username'].present? && !UserProfile::GetAccount[username: row['username']].nil?
    end
    if errors.present?
      flash[:error] = ['Error uploading student roster'] + errors
    else
      add_students(period, users)
      flash[:notice] = 'Student roster has been uploaded.'
    end
    redirect_to edit_admin_course_path(params[:id])
  end

  private
  def course_params
    { id: params[:id], course: params.require(:course)
                                     .permit(:name, teacher_ids: []) }
  end

  def get_users
    @users = GetAllUserProfiles[]
  end

  def add_students(period, users)
    users.each do |user|
      profile = create_user(user)
      AddUserAsPeriodStudent.call(period: period, user: profile.entity_user)
    end
  end

  def create_user(user)
    first_name = user['first_name']
    last_name = user['last_name']
    full_name = "#{first_name} #{last_name}" if first_name.present? && last_name.present?
    UserProfile::CreateProfile[email: user['email'], username: user['username'],
                               first_name: first_name, last_name: last_name,
                               full_name: full_name]
  end
end
