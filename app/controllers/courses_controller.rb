class CoursesController < ApplicationController
  include Lev::HandleWith

  def join
    handle_with(CoursesJoin, complete: -> { redirect_to dashboard_path })
  end
end
