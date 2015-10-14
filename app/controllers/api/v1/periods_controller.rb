class Api::V1::PeriodsController < Api::V1::ApiController
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
    course = Entity::Course.find(params[:course_id])
    period = CreatePeriod[course: course, name: period_params[:name]]
    respond_with period, represent_with: Api::V1::PeriodRepresenter
  end

  private
  def period_params
    params.require(:period).permit(:name)
  end
end
