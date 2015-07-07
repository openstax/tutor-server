class Admin::PeriodsController < Admin::BaseController
  before_action :get_course

  before_action :get_period, only: [:edit, :update]

  def new
  end

  def create
    CreatePeriod[course: @course, name: params[:period][:name]]
    redirect_to edit_admin_course_path(@course.id)
  end

  def edit
  end

  def update
    @period.update_attributes(name: params[:period][:name])
    redirect_to edit_admin_course_path(@course.id)
  end

  private
  def get_course
    @course = Entity::Course.find(params[:course_id])
  end

  def get_period
    @period = @course.periods.find(params[:id])
  end
end
