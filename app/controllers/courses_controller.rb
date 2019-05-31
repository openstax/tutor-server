class CoursesController < ApplicationController

  skip_before_action :block_sign_up, only: [:teach, :enroll]
  skip_before_action :authenticate_user!, if: :period_is_archived?

  def teach
    handle_with(CoursesTeach, success: -> {
      course = @handler_result.outputs.course
      redirect_to course_dashboard_path(course.id)
    })
  end

  protected

  def period_is_archived?
    return false if params[:enroll_token].blank?
    period = CourseMembership::GetPeriod[ enrollment_code: params[:enroll_token] ]
    period.nil? || period.archived?
  end

end
