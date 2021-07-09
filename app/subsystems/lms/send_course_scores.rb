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
  lev_routine transaction: :no_transaction, use_jobba: true

  def exec(course:)
    raise 'Course cannot be nil' if course.nil?

    @errors = []

    @course = course

    if @course.environment.current?
      callbacks = Lms::Models::CourseScoreCallback.where(course: course).where(
        CourseMembership::Models::Student.joins(:role).where(course: course, dropped_at: nil).where(
          '"entity_roles"."user_profile_id" = "lms_course_score_callbacks"."user_profile_id"'
        ).arel.exists
      )

      @course.update_attributes(last_lms_scores_push_job_id: status.id)

      @num_callbacks = callbacks.count
      @num_missing_scores = 0

      save_status_data

      callbacks.each_with_index do |callback, ii|
        score_data = course_score_data(callback.user_profile_id)

        if score_data.present? && score_data[:course_average].present?
          send_one_score(callback, score_data)
        else
          @num_missing_scores += 1
          save_status_data
        end
        status.set_progress(ii, @num_callbacks)
      end
    else
      error! message: 'This course was created in a different environment', course: @course.id
    end

    notify_errors
  end

  def save_status_data
    status.save num_callbacks: @num_callbacks, num_missing_scores: @num_missing_scores
  end

  def course_score_data(user_profile_id)
    @scores_by_user_profile_id ||= begin
      perf_report = Tasks::GetPerformanceReport[course: @course, is_teacher: true]

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
      request_xml = basic_outcome_xml(score: score_data[:course_average],
                                      sourcedid: callback.result_sourcedid)

      response = token.post(
        callback.outcome_url, request_xml, {'Content-Type' => 'application/xml'}
      )

      outcome_response = Lms::OutcomeResponse.new(response)
      raise 'lms returned failure' if outcome_response.code_major == 'failure'
    rescue StandardError => e
      error!(
        exception: e,
        message: e.message,
        course: @course.id,
        score: score_data[:course_average],
        student_name: score_data[:name],
        student_identifier: score_data[:student_identifier],
        response: response&.body
      )
    end
  end

  def error!(error)
    @errors.push(error)
    status.add_error(error)
    log_error("send_one_score failure: #{error.except(:exception).inspect}")
  end

  def log_error(message)
    Rails.logger.error do
      "[#{self.class.name}] #{'(' + status.id + ')' if status.present?} #{message}"
    end
  end

  def notify_errors
    return if @errors.empty?

    @errors.each do |error|
      exception = error[:exception]

      if exception.nil?
        Raven.capture_message error[:message], extra: error.except(:message)
      else
        Raven.capture_exception exception, extra: error.except(:exception)
      end
    end
  end

  def basic_outcome_xml(score:, sourcedid:, message_identifier: nil)
    message_identifier ||= SecureRandom.uuid

    # https://www.imsglobal.org/specs/ltiomv1p0/specification

    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.imsx_POXEnvelopeRequest(
        xmlns: 'http://www.imsglobal.org/services/ltiv1p1/xsd/imsoms_v1p0'
      ) {
        xml.imsx_POXHeader {
          xml.imsx_POXRequestHeaderInfo {
            xml.imsx_version 'V1.0'
            xml.imsx_messageIdentifier message_identifier
          }
        }
        xml.imsx_POXBody {
          xml.replaceResultRequest {
            xml.resultRecord {
              xml.sourcedGUID {
                xml.sourcedId sourcedid
              }
              xml.result {
                xml.resultScore {
                  xml.language 'en'
                  xml.textString score
                }
              }
            }
          }
        }
      }
    end

    builder.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
  end
end
