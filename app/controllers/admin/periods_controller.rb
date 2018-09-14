class Admin::PeriodsController < Admin::BaseController
  before_action :get_course, only: [:new, :create]

  before_action :get_period, only: [:edit, :update, :destroy, :restore]

  def new
  end

  def create
    result = CreatePeriod.call(course: @course,
                               name: params[:period][:name],
                               enrollment_code: params[:period][:enrollment_code])
    if result.errors.any?
      flash[:error] = result.errors.map do |err|
        "#{err.data[:attribute].to_s.humanize} #{err.message}"
      end
      redirect_to new_admin_course_period_path(@course)
    else
      flash[:notice] = "Period \"#{result.outputs.period.name}\" created."
      redirect_to edit_admin_course_path(@course.id, anchor: 'periods')
    end
  end

  def edit
  end

  def update
    if @period.update_attributes(name: params[:period][:name],
                                 enrollment_code: params[:period][:enrollment_code])
      flash[:notice] = 'Period updated.'
      redirect_to edit_admin_course_path(@course.id, anchor: 'periods')
    else
      flash[:alert] = @period.errors.full_messages
      redirect_to edit_admin_period_path(@period.id)
    end
  end

  def destroy
    result = CourseMembership::ArchivePeriod.call(period: @period)

    if result.errors.empty?
      flash[:notice] = "Period \"#{@period.name}\" archived."
    else
      flash[:error] = result.errors.full_messages
    end
    redirect_to edit_admin_course_path(@course.id, anchor: 'periods')
  end

  def restore
    result = CourseMembership::UnarchivePeriod.call(period: @period)

    if result.errors.empty?
      flash[:notice] = "Period \"#{@period.name}\" unarchived."
    else
      flash[:error] = result.errors.full_messages
    end
    redirect_to edit_admin_course_path(@course.id, anchor: 'periods')
  end

  private

  def get_course
    @course = CourseProfile::Models::Course.find(params[:course_id])
  end

  def get_period
    @period = CourseMembership::Models::Period.find(params[:id])
    @course = @period.course
  end
end
