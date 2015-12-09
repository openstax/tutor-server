class CoursesController < ApplicationController
  include Lev::HandleWith

  def join
    handle_with(CoursesJoin, complete: -> {
      course = @handler_result.course
      redirect_to course_dashboard_path(course)
    })
  end
end
