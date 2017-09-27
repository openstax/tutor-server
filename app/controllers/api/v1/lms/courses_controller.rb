class Lms::CoursesController < ActionController::Base

  before_filter :get_course

  resource_description do
    api_versions "v1"
    short_description 'LMS course actions'
    description <<-EOS
    EOS
  end

  api :GET, '/lms/courses/:id', 'Returns info on how to connect a course to a LMS system'
  description <<-EOS
    TODO
  EOS
  def show
    OSU::AccessPolicy.require_action_allowed!(:lms_connection_info, current_api_user, @course)

    app = Lms::Models::App.find_or_create_by(owner: @course)

    render json: app.as_json.merge(
             url: lms_configuration_url(format: :xml),
             xml: render_to_string(template: 'lms/configuration.xml')
           )
  end

  api :GET, '/lms/courses/:id/push_scores', 'Sends average course scores to the LMS in a background job'
  description <<-EOS
    Returns JSON of the following form with HTTP status 202:

      `{ job: api_job_path(job_id) }`

    * The job data will include an `errors` array with information about errors
      encountered during the push.  Each entry is a hash with `score`, `student_name`,
      `student_identifier`, and `lms_description` keys.  The `lms_description` is
      text returned from the LMS.
    * The job progress will be updated during the push.
  EOS
  def push_scores
    OSU::AccessPolicy.require_action_allowed!(:lms_sync_scores, current_api_user, @course)
    status_id = Lms::SendCourseScoresToLms.perform_later(course: @course)
    render_job_id_json(status_id)
  end

  protected

  def get_course
    @course = CourseProfile::Models::Course.find(params[:id])
  end

end
