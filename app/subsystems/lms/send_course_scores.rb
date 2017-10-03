require 'oauth'

# Sends course scores back to an LMS. Because it is unclear whether an LMS will
# always accept repeat pushes of grades, we have chosen to send all grades back
# in bulk when the teacher chooses to push a "sync grades" button.  It appears
# that LTI is setup to send grades back one at a time after a student completes
# an assignment -- there doesn't seem to be a "send back scores in bulk in one
# request" option, so this code is therefore not very network efficient.  This
# code is also just LTI 1 now -- looks like LTI 2 has ways to send all grades
# at once.

# References:
#   https://andyfmiller.com/2016/03/26/ims-lti-outcomes-1-0-versus-2-0/

class Lms::SendCourseScores

  lev_routine transaction: :no_transaction

  def exec(course:)
    @course = course
    raise "Course cannot be nil" if course.nil?

    callbacks = Lms::Models::CourseScoreCallback.where(course: course)

    @course.update_attributes(last_lms_scores_push_job_id: status.id)

    @num_callbacks = callbacks.count
    @num_missing_scores = 0

    save_status_data

    callbacks.each_with_index do |callback, ii|
      score_data = course_score_data(callback.user_profile_id)

      if score_data.present?
        send_one_score(callback, score_data)
      else
        @num_missing_scores += 1
        save_status_data
      end
      status.set_progress(ii, @num_callbacks)
    end
  end

  def save_status_data
    status.save({
      num_callbacks: @num_callbacks,
      num_missing_scores: @num_missing_scores,
    })
  end

  def course_score_data(user_profile_id)
    @scores_by_user_profile_id ||= begin
      perf_report = Tasks::GetTpPerformanceReport[course: @course]

      scores = perf_report.flat_map do |period_perf_report|
        period_perf_report[:students]
      end

      scores.each_with_object({}) do |score, hash|
        hash[score[:user]] = score
      end
    end

    @scores_by_user_profile_id[user_profile_id]
  end

  def token
    @token ||= begin
      app = Lms::Queries.app_for_course(@course)
      auth = OAuth::Consumer.new(app.key, app.secret)
      OAuth::AccessToken.new(auth)
    end
  end

  def send_one_score(callback, score_data)
    begin
      request_xml = basic_outcome_xml(score: score_data[:average_score],
                                      sourcedid: callback.result_sourcedid)

      response = token.post(
        callback.outcome_url, request_xml, {'Content-Type' => 'application/xml'}
      )

      Rails.logger.debug { response.body }

      outcome_response = Lms::OutcomeResponse.new(response)

      if "failure" == outcome_response.code_major
        error!({
          score: score_data[:average_score],
          student_name: score_data[:name],
          student_identifier: score_data[:student_identifier],
          lms_description: outcome_response.description
        })
      end
    rescue StandardError => ee
      error!({
        score: score_data[:average_score],
        student_name: score_data[:name],
        student_identifier: score_data[:student_identifier],
        unhandled_error: ee.message
      })
    end
  end

  def error!(message)
    status.add_error(message)
    log_error("send_one_score failure: #{message.inspect}")
  end

  def log_error(message)
    Rails.logger.error { "[#{self.class.name}] #{'(' + status.id + ')' if status.present?} #{message}"}
  end

  def basic_outcome_xml(score:, sourcedid:, message_identifier: nil)
    message_identifier ||= SecureRandom.uuid

    # https://www.imsglobal.org/specs/ltiomv1p0/specification

    <<-EOS
      <?xml version = "1.0" encoding = "UTF-8"?>
      <imsx_POXEnvelopeRequest xmlns="http://www.imsglobal.org/services/ltiv1p1/xsd/imsoms_v1p0">
        <imsx_POXHeader>
          <imsx_POXRequestHeaderInfo>
            <imsx_version>V1.0</imsx_version>
            <imsx_messageIdentifier>#{message_identifier}</imsx_messageIdentifier>
          </imsx_POXRequestHeaderInfo>
        </imsx_POXHeader>
        <imsx_POXBody>
          <replaceResultRequest>
            <resultRecord>
              <sourcedGUID>
                <sourcedId>#{sourcedid}</sourcedId>
              </sourcedGUID>
              <result>
                <resultScore>
                  <language>en</language>
                  <textString>#{score}</textString>
                </resultScore>
              </result>
            </resultRecord>
          </replaceResultRequest>
        </imsx_POXBody>
      </imsx_POXEnvelopeRequest>
    EOS
  end

end
