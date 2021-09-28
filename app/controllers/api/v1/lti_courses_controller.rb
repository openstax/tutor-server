class Api::V1::LtiCoursesController < Api::V1::ApiController
  resource_description do
    api_versions 'v1'
    short_description 'LTI 1.3 courses controller'
    description <<-EOS
      Handles pairing courses to LTI 1.3 contexts and
      updating score data using the Assignment and Grade Services
    EOS
  end

  api :PUT, '/lti/courses/:id/scores',
            "Sends assignment scores to the paired context's platform in a background job"
  description <<-EOS
    TODO: Update

    Returns JSON of the following form with HTTP status 202:

      `{ job: api_job_path(job_id) }`

    When the job data is retrieved, it will contain a list of errors and a data field.

    Each error in the list will have the following values:

    * `error`: the text returned from the LMS about the error
    * `score`: the score that we tried to send
    * `student_name`: the name of the student for which the error occurred
    * `student_identifier`: the student's self-supplied student ID

    The data field will contain the following values:

    * `num_callbacks`: The number of URL callbacks to the LMS that Tutor has for this course.  This
      is the maximum number of socres that can be sent.
    * `num_missing_scores`: The number of scores that were not found in Tutor (likely because the
      student hasn't worked an assignment or because no assignments have become due)

    The number of errors + `num_missing_scores` should equal `num_callbacks` unless some other
    unhandled error occurred.

    The job progress will be updated during the push.
  EOS
  def scores
    OSU::AccessPolicy.require_action_allowed! :lti_scores, current_api_user, course
    render_job_id_json UpdateLtiScores.perform_later(course: course)
  end

  protected

  def course
    @course ||= CourseProfile::Models::Course.find params[:id]
  end
end
