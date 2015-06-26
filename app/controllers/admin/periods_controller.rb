class Admin::PeriodsController < Admin::BaseController
  before_action :get_course

  def new
  end

  def create
    CreatePeriod[course: @course, name: params[:period][:name]]
    redirect_to edit_admin_course_path(@course.id)
  end

  private
  def get_course
    @course = Entity::Course.find(params[:course_id])
  end
end
