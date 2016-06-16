class ShortCodesController < ApplicationController

  def redirect
    handle_with(
      ShortCode::ShortCodeRedirect,
        success: -> (*) { redirect_to @handler_result.outputs.uri },
        failure: -> (*) {
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
          when :invalid_user
            raise SecurityTransgression
          else
            raise StandardError, "#{@handler_result.errors.map(&:code).join(', ')}"
          end
        })
  end

  protected

  def error_page(heading, body)
    render 'static_pages/generic_error',
           locals: { heading: heading, body: body },
           status: :unprocessable_entity
  end

end

class ShortCodeNotFound < StandardError; end
