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
    teachers = entity_course.teachers.includes(role: { user: { profile: :account } })
    @teachers = teachers.collect { |t| t.role.user.profile }
    @books = Content::ListBooks[]
    @course_book = entity_course.books.first
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
    # Upload a csv file with columns: first_name, last_name, username and email or password.
    period = CourseMembership::Models::Period.find(params[:course][:period])
    roster_file = params[:student_roster]
    csv_reader = CSV.new(roster_file.read, headers: true)
    users = []
    errors = []
    csv_reader.each do |row|
      users << row
      errors << "On line #{csv_reader.lineno}, username is missing." unless row['username'].present?
      errors << "On line #{csv_reader.lineno}, either an email or a password is required." \
        unless row['password'].present? || row['email'].present?
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

  def set_book
    if params[:book_id].blank?
      flash[:error] = 'Please select a course book'
      return redirect_to edit_admin_course_path(params[:id])
    end

    course = Entity::Course.find(params[:id])
    book = Entity::Book.find(params[:book_id])
    if course.books.include?(book)
      flash[:notice] = "Course book \"#{book.root_book_part.title}\" is already selected for \"#{course.profile.name}\""
    else
      CourseContent::AddBookToCourse.call(course: course, book: book, remove_other_books: true)
      flash[:notice] = "Course book \"#{book.root_book_part.title}\" selected for \"#{course.profile.name}\""
    end
    redirect_to edit_admin_course_path(params[:id])
  end

  private
  def course_params
    { id: params[:id], course: params.require(:course)
                                     .permit(:name,
                                             :course_detail_school_id,
                                             teacher_ids: []) }
  end

  def get_schools
    @schools = CourseDetail::ListSchools[]
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
    UserProfile::CreateProfile[username: user['username'],
                               password: user['password'],
                               email: user['email'],
                               first_name: first_name,
                               last_name: last_name,
                               full_name: full_name]
  end
end
