class CoursesController < ApplicationController
  include Lev::HandleWith

  def join
    handle_with(CoursesJoin, success: -> { redirect_to dashboard_path },
                             failure: -> {
                               @handler_result.errors.each do |e|
                                 CoursesJoin.handle_error(e)
                               end
                             })
  end
end
