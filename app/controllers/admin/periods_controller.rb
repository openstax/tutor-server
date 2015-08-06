class Admin::PeriodsController < Admin::BaseController
  before_action :get_course, only: [:new, :create]

  before_action :get_period, only: [:edit, :update, :destroy]

  def new
  end

  def create
    period = CreatePeriod[course: @course, name: params[:period][:name]]
    flash[:notice] = "Period \"#{period.name}\" created."
    redirect_to edit_admin_course_path(@course.id)
  end

  def edit
  end

  def update
    @period.update_attributes(name: params[:period][:name])
    flash[:notice] = 'Period updated.'
    redirect_to edit_admin_course_path(@course.id)
  end

  def destroy
    if @period.destroy
      flash[:notice] = "Period \"#{@period.name}\" deleted."
    else
      flash[:error] = @period.errors.full_messages
    end
    redirect_to edit_admin_course_path(@course.id)
  end

  private
  def get_course
    @course = Entity::Course.find(params[:course_id])
  end

  def get_period
    @period = CourseMembership::Models::Period.find(params[:id])
    @course = @period.course
  end
end
