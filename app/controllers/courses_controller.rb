class CoursesController < ApplicationController
  include Lev::HandleWith

  def join
    handle_with(CoursesJoin, success: -> {
      course = @handler_result.outputs.course
      redirect_to "/courses/#{course.id}"
    },
    failure: -> {
      binding.pry
      flash[:error] = @handler_result.errors.first.message
      redirect_to dashboard_path
    })
  end
end
