class Admin::PeriodsController < Admin::BaseController
  before_action :get_course, only: [:new, :create]

  before_action :get_period, only: [:edit, :update, :destroy, :restore, :change_salesforce]

  def new
  end

  def create
    period = CreatePeriod[course: @course, name: params[:period][:name]]
    flash[:notice] = "Period \"#{period.name}\" created."
    redirect_to edit_admin_course_path(@course.id, anchor: 'periods')
  end

  def edit
  end

  def update
    unless params[:period][:enrollment_code].present?
      flash[:error] = 'Enrollment code required.'
      redirect_to edit_admin_period_path(@period.id)
      return
    end
    @period.update_attributes(name: params[:period][:name],
                              enrollment_code: params[:period][:enrollment_code])
    flash[:notice] = 'Period updated.'
    redirect_to edit_admin_course_path(@course.id, anchor: 'periods')
  end

  def destroy
    if @period.destroy
      flash[:notice] = "Period \"#{@period.name}\" archived."
    else
      flash[:error] = @period.errors.full_messages
    end
    redirect_to edit_admin_course_path(@course.id, anchor: 'periods')
  end

  def restore
    if @period.restore(recursive: true)
      flash[:notice] = "Period \"#{@period.name}\" restored."
    else
      flash[:error] = @period.errors.full_messages
    end
    redirect_to edit_admin_course_path(@course.id, anchor: 'periods')
  end

  def change_salesforce
    handle_with(Admin::PeriodsChangeSalesforce,
                success: ->(*) {
                  flash[:notice] = "Salesforce record changed. Stats won't update til next periodic update."
                  redirect_to edit_admin_course_path(@course, anchor: "salesforce")
                },
                failure: ->(*) {
                  flash[:error] = @handler_result.errors.map(&:translate).join(', ')
                  redirect_to edit_admin_course_path(@course, anchor: "salesforce")
                })
  end

  private

  def get_course
    @course = Entity::Course.find(params[:course_id])
  end

  def get_period
    @period = CourseMembership::Models::Period.with_deleted.find(params[:id])
    @course = @period.course
  end
end
