class ShortCodesController < ApplicationController

  # ShortCodes currently require an authenticated user in order to detect the appropriate role for a course
  # In the future, this requirement could be removed by adding a `requires_authentication` flag to the short_codes table
  # If and when that occurs, authentication could be skipped by doing something like:
  # skip_before_filter :authenticate_user!, if: ->(*) { current_short_code.requires_authentication? }

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
