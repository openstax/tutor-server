class CoursesController < ApplicationController
  include Lev::HandleWith

  def join
    handle_with(CoursesJoin, complete: -> {
      course = @handler_result.outputs.course
      redirect_to "/courses/#{course.id}"
    })
  end
end
