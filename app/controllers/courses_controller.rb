class CoursesController < ApplicationController
  include Lev::HandleWith # TODO not already included?

  def teach
    handle_with(CoursesTeach, complete: -> {
      course = @handler_result.outputs.course
      redirect_to course_dashboard_path(course)
    })
  end

  def enroll
    handle_with(CoursesEnroll,
                success: -> {
                  course = @handler_result.outputs.course
                  redirect_to course_dashboard_path(course)
                },
                failure: -> {
                  if @handler_result.errors.map(&:code) == :user_is_already_a_course_student
                    course = @handler_result.outputs.course
                    redirect_to course_dashboard_path(course, notice: "You are already enrolled in this course.")
                  else
                    raise StandardError, "Student URL enrollment failed: #{@handler_result.errors}"
                  end
                })
  end
end
