class Api::V1::PeriodsController < Api::V1::ApiController
  before_filter :find_course, only: :create
  before_filter :find_period, only: :update
  before_filter :ensure_requestor_is_course_teacher

  resource_description do
    api_versions "v1"
    short_description 'Represents course periods in the system'
    description <<-EOS
      Period description to be written...
    EOS
  end

  api :POST, '/courses/:course_id/periods(/role/:role_id)',
             'Returns a new course period for given course'
  description <<-EOS
    #{json_schema(Api::V1::PeriodRepresenter, include: :readable)}
  EOS
  def create
    period = CreatePeriod[course: @course, name: period_params[:name]]
    respond_with period, represent_with: Api::V1::PeriodRepresenter, location: nil
  end

  api :PATCH, '/periods/:id(/role/:role_id)',
              'Returns an updated period for the given course'
  description <<-EOS
    #{json_schema(Api::V1::PeriodRepresenter, include: :readable)}
  EOS
  def update
    updated_period = UpdatePeriod[period: @period, name: period_params[:name]]
    respond_with updated_period, represent_with: Api::V1::PeriodRepresenter, location: nil
  end

  private
  def find_course
    @course = Entity::Course.find(params[:course_id])
  end

  def find_period
    @period = GetPeriod[id: params[:id]].to_model
  end

  def ensure_requestor_is_course_teacher
    unless UserIsCourseTeacher[course: @course || @period.course,
                               user: current_human_user]
      raise SecurityTransgression
    end
  end

  def period_params
    params.require(:period).permit(:name)
  end
end
