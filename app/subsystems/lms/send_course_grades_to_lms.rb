require 'oauth'

class Lms::SendCourseGradesToLms

  lev_routine transaction: :no_transaction

  def exec(course:)

    #######################################################################
    #
    # NOTE!
    #
    # Consider the below code as pseudocode.  I took Nathan's working code
    # that submitted a random grade back immediately upon launch, and gave
    # it this new home with some broad strokes of a real implementation.
    #
    # This code (1) will probably explode in 8 different ways, and (2) could
    # use being reorganized so we send grades in bulk, and (3) probably 4 other
    # things I am not even thinking of.
    #
    # Rewrite this code :-)
    #
    # NOTE also that CourseGradeCallbacks are now stored in terms of user/course
    # pairs instead of students.
    #
    #######################################################################

    app = Lms::Models::App.where(app_owner: course).first
    fatal_error(code: :no_app_found_for_course) if app.nil?

    course.students.find_each do |student|
      score = sprintf('%0.2f', rand) # FIXME

      callbacks = Lms::Models::CourseGradeCallback.where(student: student).each do |callback|
        auth = OAuth::Consumer.new(app.key, app.secret)
        token = OAuth::AccessToken.new(auth)

        xml = render_to_string(
          template: 'lms/random_outcome.xml',
          locals: {
            :@score => score,
            :@source_id => callback.result_sourcedid
          }
        )
        response = token.post(
          callback.outcome_url, xml, {'Content-Type' => 'application/xml'}
        )

        Rails.logger.debug response.body
      end
    end
  end

end

