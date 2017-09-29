class Api::V1::Lms::CoursesController < Api::V1::ApiController

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

  api :PUT, '/lms/courses/:id/push_scores', 'Sends average course scores to the LMS in a background job'
  description <<-EOS
    Returns JSON of the following form with HTTP status 202:

      `{ job: api_job_path(job_id) }`

    When the job data is retrieved, it will contain a list of errors and a data field.

    Each error in the list will have the following values:

    * `score`: the score that we tried to send.
    * `student_name`: the name of the student for which the error occurred.
    * `student_identifier`: the student's self-supplied student ID
    * `lms_description`: the text returned from the LMS about the error.

    The data field will contain the following values:

    * `num_callbacks`: The number of URL callbacks to the LMS that Tutor has for this course.  This
      is the maximum number of socres that can be sent.
    * `num_missing_scores`: The number of scores that were not found in Tutor (likely because the
      student hasn't worked an assignment or because no assignments have become due)

    The number of errors + `num_missing_scores` should equal `num_callbacks` unless some other
    unhandled error occurred.

    The job progress will be updated during the push.
  EOS
  def push_scores
    OSU::AccessPolicy.require_action_allowed!(:lms_sync_scores, current_api_user, @course)
    status_id = ::Lms::SendCourseScores.perform_later(course: @course)
    render_job_id_json(status_id)
  end

  protected

  def get_course
    @course = CourseProfile::Models::Course.find(params[:id])
  end

end
