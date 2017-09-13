class Admin::CoursesController < Admin::BaseController
  include Manager::CourseDetails
  include Lev::HandleWith

  before_action :get_schools, :get_catalog_offerings, only: [:new, :edit]

  def index
    @query = params[:query]
    @order_by = params[:order_by]
    result = SearchCourses.call(query: params[:query], order_by: params[:order_by] || 'id')
    per_page = params[:per_page] || 25
    per_page = result.outputs.total_count if params[:per_page] == 'all'
    params_for_pagination = { page: (params[:page] || 1), per_page: per_page }

    if result.errors.any?
      flash[:error] = "Invalid search"
      redirect_to admin_courses_path and return
    end

    @course_infos = result.outputs.items.preload(
      [
        { teachers: { role: [:role_user, :profile] },
          periods_with_deleted: :latest_enrollments_with_deleted,
          ecosystems: :books },
        :periods
      ]
    ).try(:paginate, params_for_pagination)

    @ecosystems = Content::ListEcosystems[]
    result = CollectJobsData.call job_name: 'CourseContent::AddEcosystemToCourse'
    @incomplete_jobs = result.outputs.incomplete_jobs
    @failed_jobs = result.outputs.failed_jobs
  end

  def new
    get_new_course
  end

  def create
    handle_with(Admin::CoursesCreate,
                success: ->(*) {
                  flash.notice = 'The course has been created.'
                  redirect_to admin_courses_path
                },
                failure: ->(*) {
                  flash.now[:error] = @handler_result.errors.full_messages
                  @course = @handler_result.outputs.course || get_new_course
                  get_schools
                  get_catalog_offerings
                  render :new
                })
  end

  def add_salesforce
    handle_with(Admin::CoursesAddSalesforce,
                success: ->(*) {
                  flash[:notice] = 'The given Salesforce record has been attached to the course.'
                  redirect_to edit_admin_course_path(params[:id], anchor: "salesforce")
                },
                failure: ->(*) {
                  flash[:error] = @handler_result.errors.map(&:translate).join(', ')
                  redirect_to edit_admin_course_path(params[:id], anchor: "salesforce")
                })
  end

  def remove_salesforce
    handle_with(Admin::CoursesRemoveSalesforce,
                success: ->(*) {
                  flash[:notice] = 'Removal of Salesforce record from course was successful.'
                  redirect_to edit_admin_course_path(params[:id], anchor: "salesforce")
                },
                failure: ->(*) {
                  flash[:error] = @handler_result.errors.map(&:translate).join(', ')
                  redirect_to edit_admin_course_path(params[:id], anchor: "salesforce")
                })
  end

  def restore_salesforce
    Salesforce::Models::AttachedRecord
      .with_deleted
      .find(params[:restore_salesforce][:attached_record_id])
      .restore
    redirect_to edit_admin_course_path(params[:id], anchor: "salesforce")
  end

  def edit
    get_course_details
  end

  def update
    handle_with(Admin::CoursesUpdate,
                params: course_params,
                success: ->(*) {
                  flash[:notice] = 'The course has been updated.'
                  redirect_to edit_admin_course_path(params[:id])
                },
                failure: ->(*) {
                  flash.now[:error] = @handler_result.errors.full_messages
                  @course = CourseProfile::Models::Course.find(params[:id])
                  get_schools
                  get_catalog_offerings
                  get_course_details
                  render :edit
                })
  end

  def destroy
    handle_with(Admin::CoursesDestroy,
                success: ->(*) {
                  flash[:notice] = 'The course has been deleted.'
                  redirect_to admin_courses_path
                },
                failure: ->(*) {
                  flash[:alert] = 'The course could not be deleted because it is not empty.'
                  redirect_to admin_courses_path
                })
  end

  def bulk_update
    case params[:commit]
    when 'Set Ecosystem'
      bulk_set_ecosystem
    when 'Set Flag'
      bulk_set_flag
    end
  end

  def bulk_set_ecosystem
    if params[:ecosystem_id].blank?
      flash[:error] = 'Please select an ecosystem'
    elsif params[:course_id].blank?
      flash[:error] = 'Please select the courses'
    else
      course_ids = params[:course_id]
      ecosystem = Content::Models::Ecosystem.find(params[:ecosystem_id])
      courses = CourseProfile::Models::Course
        .where { id.in course_ids }
        .preload(:ecosystems)
        .select { |course| course.ecosystems.first.try(:id) != ecosystem.id }
      courses.each do |course|
        job_id = CourseContent::AddEcosystemToCourse.perform_later(
          course: course, ecosystem: ecosystem
        )
        job = Jobba.find(job_id)
        job.save(
          course_id: course.id,
          course_name: course.name,
          ecosystem_id: ecosystem.id,
          ecosystem_title: ecosystem.title
        )
      end
      flash[:notice] = 'Course ecosystem updates have been queued.'
    end

    redirect_to admin_courses_path
  end

  def bulk_set_flag
    if params[:flag_name].blank?
      flash[:error] = 'Select a flag to modify'
    else
      # if select all on all pages, rerun query and get all course IDs

      if params[:courses_select_all_on_all_pages] == 'on'
        course_ids = SearchCourses[query: params[:query]].reorder(nil).pluck(:id)
      else
        course_ids = params[:course_id]
      end

      begin
        CourseProfile::Models::Course.transaction do
          CourseProfile::Models::Course
            .where(id: course_ids)
            .find_each do |course|
              course.send("#{params[:flag_name]}=", params[:flag_value].to_s == "true")
              course.save!
            end
        end
        flash[:notice] = 'Flag values were updated'
      rescue ActiveRecord::RecordInvalid => invalid
        flash[:error] = "Could not update flag value for at least one course, rolled back all changes: #{invalid.message}"
      end
    end

    redirect_to admin_courses_path(query: params[:query], order_by: params[:order_by])
  end

  def roster
    handle_with(
      Admin::CoursesRoster,
      success: -> { flash[:notice] = 'Student roster import has been queued.' },
      failure: -> { flash[:error] = @handler_result.errors.map(&:message).flatten }
    )

    redirect_to edit_admin_course_path(params[:id], anchor: 'roster')
  end

  def set_ecosystem
    if params[:ecosystem_id].blank?
      flash[:error] = 'Please select a course ecosystem'
    else
      course = CourseProfile::Models::Course.find(params[:id])
      current_ecosystem = GetCourseEcosystem[course: course]

      if current_ecosystem.try!(:id).to_s == params[:ecosystem_id]
        flash[:notice] = "Course ecosystem \"#{current_ecosystem.title
                         }\" is already selected for \"#{course.name}\""
      else
        new_ecosystem = Content::Models::Ecosystem.find(params[:ecosystem_id])

        CourseContent::AddEcosystemToCourse.perform_later course: course, ecosystem: new_ecosystem
        flash[:notice] = "Course ecosystem update to \"#{new_ecosystem.title
                         }\" queued for \"#{course.name}\""
      end
    end

    redirect_to edit_admin_course_path(params[:id], anchor: 'content')
  end

  private

  def get_new_course
    current_time = Time.current

    @course = CourseProfile::Models::Course.new(
      is_concept_coach: false,
      is_college: true,
      term: 'demo',
      year: current_time.year,
      starts_at: current_time,
      ends_at: current_time + 6.months
    )
  end

  def course_params
    {
      id: params[:id],
      course: params.require(:course).permit(
        :name,
        :term,
        :year,
        :starts_at,
        :ends_at,
        :is_concept_coach,
        :is_college,
        :is_test,
        :does_cost,
        :catalog_offering_id,
        :appearance_code,
        :school_district_school_id,
        :is_excluded_from_salesforce,
        teacher_ids: []
      )
    }
  end

  def get_schools
    @schools = SchoolDistrict::ListSchools[]
  end

  def get_catalog_offerings
    @catalog_offerings = Catalog::ListOfferings[]
  end
end
