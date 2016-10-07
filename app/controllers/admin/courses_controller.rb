class Admin::CoursesController < Admin::BaseController
  include Manager::CourseDetails
  include Lev::HandleWith

  before_action :get_schools, :get_catalog_offerings, only: [:new, :edit]

  def index
    @query = params[:query]
    courses = SearchCourses.call(query: params[:query], order_by: params[:order_by] || 'id')
    params[:per_page] = courses.outputs.total_count if params[:per_page] == "all"
    params_for_pagination = {page: params.fetch(:page, 1), per_page: params.fetch(:per_page, 25)}

    if courses.errors.any?
      flash[:error] = "Invalid search"
      redirect_to admin_courses_path and return
    end

    @course_infos = courses.outputs.items.preload(
      [
        :profile, { teachers: { role: [:role_user, :profile] }, periods_with_deleted: :latest_enrollments_with_deleted }
      ],
      [ ecosystems: [:books] ],
      [ :periods ]
    ).try(:paginate, params_for_pagination)

    @ecosystems = Content::ListEcosystems[]
    @incomplete_jobs = CollectImportJobsData[state: :incomplete]
    @failed_jobs = CollectImportJobsData[state: :failed]
    @job_path_proc = ->(job_id) { admin_job_path(job_id) }
  end

  def new
    get_new_course_profile
  end

  def create
    handle_with(Admin::CoursesCreate,
                success: ->(*) {
                  flash.notice = 'The course has been created.'
                  redirect_to admin_courses_path
                },
                failure: ->(*) {
                  flash[:error] = @handler_result.errors.full_messages
                  @profile = @handler_result.outputs.profile || get_new_course_profile
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
                complete: ->(*) {
                  flash[:notice] = 'The course has been updated.'
                  redirect_to admin_courses_path
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
    end
  end

  def bulk_set_ecosystem
    if params[:ecosystem_id].blank?
      flash[:error] = 'Please select an ecosystem'
    elsif params[:course_id].blank?
      flash[:error] = 'Please select the courses'
    else
      course_ids = params[:course_id]
      ecosystem = ::Content::Ecosystem.find(params[:ecosystem_id])
      courses = Entity::Course
        .where { id.in course_ids }
        .includes(:ecosystems)
        .select { |course|
          course.ecosystems.first.try(:id) != ecosystem.id
        }
      courses.each do |course|
        job_id = CourseContent::AddEcosystemToCourse.perform_later(
          course: Marshal.dump(course.reload),
          ecosystem: Marshal.dump(ecosystem)
        )
        job = Jobba.find(job_id)
        job.save(course_ecosystem: ecosystem.title, course_id: course.id)
      end
      flash[:notice] = 'Course ecosystem update background jobs queued.'
    end

    redirect_to admin_courses_path
  end

  def students
    handle_with(Admin::CoursesStudents, success: -> {
      flash[:notice] = 'Student roster has been uploaded.'
    },
    failure: -> {
      flash[:error] = ['Error uploading student roster'] +
                        @handler_result.errors.map(&:message).flatten

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
        CourseContent::AddEcosystemToCourse.perform_later(
          course: Marshal.dump(course.reload),
          ecosystem: Marshal.dump(ecosystem)
        )
        flash[:notice] = "Course ecosystem update to \"#{ecosystem.title}\" queued for \"#{course.profile.name}\""
      end
    end

    redirect_to edit_admin_course_path(params[:id], anchor: 'content')
  end

  private

  def get_new_course_profile
    @profile = CourseProfile::Models::Profile.new(
      is_concept_coach: false, is_college: true,
      starts_at: Time.current, ends_at: Time.current + 6.months
    )
  end

  def course_params
    {
      id: params[:id],
      course: params.require(:course).permit(:name,
                                             :catalog_offering_id,
                                             :appearance_code,
                                             :school_district_school_id,
                                             :is_concept_coach,
                                             :is_college,
                                             :starts_at,
                                             :ends_at,
                                             teacher_ids: [])
    }
  end

  def get_schools
    @schools = SchoolDistrict::ListSchools[]
  end

  def get_catalog_offerings
    @catalog_offerings = Catalog::ListOfferings[]
  end
end
