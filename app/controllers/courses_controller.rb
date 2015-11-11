class CoursesController < ApplicationController
  include Lev::HandleWith

  def join
    handle_with(CoursesJoin, success: -> { redirect_to dashboard_path },
                             failure: -> {
                               error_code = @handler_result.errors.first.code
                               raise CoursesJoin.handled_exceptions[error_code]
                             })
  end
end
