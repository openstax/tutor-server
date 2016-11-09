class CoursesController < ApplicationController

  skip_before_filter :authenticate_user!, if: :period_is_archived?

  def teach
    handle_with(CoursesTeach, complete: -> { send_to_course_dashboard })
  end

  def enroll
    handle_with(CoursesEnroll,
                success: -> {},
                failure: -> {
                  handle_enrollment_failures(@handler_result.errors.map(&:code).first)
                })
  end

  def confirm_enrollment
    handle_with(CoursesConfirmEnrollment,
                success: -> {
                  send_to_course_dashboard(
                    notice: "Enrollment successful! It may take a few " \
                            "minutes to build your assignments."
                  )
                },
                failure: -> {
                  handle_enrollment_failures(@handler_result.errors.map(&:code).first)
                })
  end

  private

  def period_is_archived?
    return false if params[:enroll_token].blank?
    period = CourseMembership::GetPeriod[ enrollment_code: params[:enroll_token] ]
    period.nil? || period.deleted?
  end

  def handle_enrollment_failures(error_code)
    case error_code
    when :period_is_archived
      render :archived_enrollment
    when :user_is_already_a_course_student
      send_to_course_dashboard(notice: "You are already enrolled in this course.")
    when :user_is_dropped
      render :dropped_student
    when :enrollment_code_not_found
      enrollment_code_not_found
    when :taken
      flash[:error] = 'That school-issued ID is already in use. If you already have an account, ' \
                      'please do not create another account or you may lose previous work. ' \
                      'Click Logout above, and sign in to your original account.'
      redirect_to token_enroll_path(params[:enroll][:enrollment_token])
    else
      raise StandardError, "Student URL enrollment failed: #{@handler_result.errors}"
    end
  end

  def send_to_dashboard(notice: nil)
    redirect_to dashboard_path, webview_notice: notice
  end

  def send_to_course_dashboard(notice: nil)
    course = @handler_result.outputs.course
    redirect_to course_dashboard_path(course.id), webview_notice: notice
  end


  def enrollment_code_not_found
    render 'static_pages/generic_error',
            locals: {
              heading: 'Invalid enrollment URL',
              body: <<-BODY
                You are trying to enroll in a class as a student, but the URL you used
                is either out of date or does not correspond to an existing course.
                Please contact your instructor for a new enrollment URL.
              BODY
            }
  end

end
