class ShortCodesController < ApplicationController

  def redirect
    handle_with(
      ShortCode::ShortCodeRedirect,
        success: ->(*) { redirect_to @handler_result.outputs.uri },
        failure: ->(*) {
          case @handler_result.errors.first.code
          when :plan_not_published
            error_page('This assignment is not yet available.',
                       <<-BODY
                         You are trying to access an assignment that is not yet available.
                         Please contact your instructor to find out when this assignment will
                         become available.
                       BODY
                      )
          when :task_not_open
            error_page('This assignment is not yet open.',
                       <<-BODY
                         You are trying to access an assignment that is not yet open.
                         Please contact your instructor to find out when this assignment will
                         become open.
                       BODY
                      )
          when :short_code_not_found
            raise ShortCodeNotFound
          when :authentication_required
            authenticate_user!
          when :user_not_in_course_with_required_role
            body = "To enroll in this course, please ask your instructor for the course enrollment link."
            error_page('You are not enrolled in this course.', body, :forbidden, false)
          else
            raise StandardError, "#{@handler_result.errors.map(&:code).join(', ')}"
          end
        })
  end

  protected

  def error_page(heading, body, status=:unprocessable_entity, show_apology=true)
    render 'static_pages/generic_error',
           locals: { heading: heading, body: body, show_apology: show_apology },
           status: status
  end

end

class ShortCodeNotFound < StandardError; end
