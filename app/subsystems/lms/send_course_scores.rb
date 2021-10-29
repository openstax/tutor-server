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
    raise 'This course was created in a different environment' unless course.environment.current?

    students = course.students.joins(role: { profile: :account }).where(
      dropped_at: nil
    ).order(:created_at).preload(role: { profile: :account }).to_a
    callbacks_by_user_id = Lms::Models::CourseScoreCallback.where(
      course: course, user_profile_id: students.map { |student| student.role.user_profile_id }
    ).index_by(&:user_profile_id)

    course.update_attribute :last_lms_scores_push_job_id, status.id

    @errors = []
    @course = course
    @num_students = students.size
    @num_callbacks = callbacks_by_user_id.size
    @num_missing_scores = 0

    save_status_data

    students.each_with_index do |student, ii|
      user_profile_id = student.role.user_profile_id
      score_data = course_score_data user_profile_id
      callback = callbacks_by_user_id[user_profile_id]

      if score_data.blank? || score_data[:course_average].blank?
        error!(
          message: 'No course average',
          course: @course.id,
          student_name: student.name,
          student_identifier: student.student_identifier
        )

        @num_missing_scores += 1
        save_status_data
      elsif callback.blank?
        error!(
          message: 'Student not linked to LMS',
          course: @course.id,
          score: score_data[:course_average],
          student_name: score_data[:name],
          student_identifier: score_data[:student_identifier]
        )
      else
        send_one_score(callback, score_data)
      end

      status.set_progress(ii, @num_students)
    end

    notify_errors
  end

  def save_status_data
    status.save(
      num_students: @num_students,
      num_callbacks: @num_callbacks,
      num_missing_scores: @num_missing_scores
    )
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
      request_xml = basic_outcome_xml(
        score: score_data[:course_average], sourcedid: callback.result_sourcedid
      )

      response = token.post(
        callback.outcome_url, request_xml, { 'Content-Type' => 'application/xml' }
      )

      outcome_response = Lms::OutcomeResponse.new(response)
      raise 'LMS returned failure code' if outcome_response.code_major == 'failure'
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
    log_error("[#{self.class.name}] failure: #{error.except(:exception).inspect}")
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
