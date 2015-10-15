class Api::V1::PeriodsController < Api::V1::ApiController
  before_filter :find_period_and_course

  before_filter -> {
    OSU::AccessPolicy.require_action_allowed!(:add_period, current_human_user, @course)
  }, only: :create

  before_filter -> {
    OSU::AccessPolicy.require_action_allowed!(:update, current_human_user, @period)
  }, only: :update

  resource_description do
    api_versions "v1"
    short_description 'Represents course periods in the system'
    description <<-EOS
      Period description to be written...
    EOS
  end

  api :POST, '/courses/:course_id/periods',
             'Returns a new course period for given course'
  description <<-EOS
    #{json_schema(Api::V1::PeriodRepresenter, include: :readable)}
  EOS
  def create
    period = CreatePeriod[course: @course, name: period_params[:name]]
    respond_with period, represent_with: Api::V1::PeriodRepresenter, location: nil
  end

  api :PATCH, '/periods/:id',
              'Returns an updated period for the given course'
  description <<-EOS
    #{json_schema(Api::V1::PeriodRepresenter, include: :readable)}
  EOS
  def update
    updated_period = CourseMembership::UpdatePeriod[period: @period,
                                                    name: period_params[:name]]
    respond_with updated_period, represent_with: Api::V1::PeriodRepresenter,
                                 location: nil,
                                 responder: ResponderWithPutContent
  end

  private
  def find_period_and_course
    if params[:course_id]
      @course = Entity::Course.find(params[:course_id])
    elsif params[:id]
      @period = CourseMembership::GetPeriod[id: params[:id]]
      @course = @period.course
    end
  end

  def period_params
    params.require(:period).permit(:name)
  end
end
