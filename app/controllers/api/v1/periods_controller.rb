class Api::V1::PeriodsController < Api::V1::ApiController
  before_filter :find_course, :ensure_requestor_is_course_teacher

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

  private
  def find_course
    @course = Entity::Course.find(params[:course_id])
  end

  def ensure_requestor_is_course_teacher
    unless UserIsCourseTeacher[course: @course, user: current_human_user]
      raise SecurityTransgression
    end
  end

  def period_params
    params.require(:period).permit(:name)
  end
end
