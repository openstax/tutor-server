class Api::V1::PeriodsController < Api::V1::ApiController
  before_action :find_period_and_course

  resource_description do
    api_versions "v1"
    short_description 'Represents course periods in the system'
    description <<-EOS
      Period description to be written...
    EOS
  end

  api :POST, '/courses/:course_id/periods', 'Returns a new course period for given course'
  description <<-EOS
    #{json_schema(Api::V1::PeriodRepresenter, include: :readable)}
  EOS
  def create
    OSU::AccessPolicy.require_action_allowed!(:add_period, current_human_user, @course)
    result = CreatePeriod.call(course: @course, **consumed(Api::V1::PeriodRepresenter))

    render_api_errors(result.errors) || respond_with(
      result.outputs.period,
      represent_with: Api::V1::PeriodRepresenter,
      location: nil
    )
  end

  api :PATCH, '/periods/:id', 'Returns an updated period for the given course'
  description <<-EOS
    #{json_schema(Api::V1::PeriodRepresenter, include: :readable)}
  EOS
  def update
    OSU::AccessPolicy.require_action_allowed!(:update, current_human_user, @period)

    result = CourseMembership::UpdatePeriod.call(
      period: @period,
      **consumed(Api::V1::PeriodRepresenter)
    )

    render_api_errors(result.errors) || respond_with(
      result.outputs.period,
      represent_with: Api::V1::PeriodRepresenter,
      location: nil,
      responder: ResponderWithPutPatchDeleteContent
    )
  end

  api :DELETE, '/periods/:id', 'Archives a period for the teacher'
  description <<-EOS
    Archives the given period.
    Must be a course teacher.

    Possible error code: period_is_already_deleted

    #{json_schema(Api::V1::PeriodRepresenter, include: :readable)}
  EOS
  def destroy
    standard_destroy(@period.to_model, Api::V1::PeriodRepresenter)
  end

  api :PUT, '/periods/:id/restore', 'Restores an archived period for the teacher'
  description <<-EOS
    Restores the given archived period.
    Must be a course teacher.

    Possible error code: period_is_not_deleted
                         name_has_already_been_taken

    #{json_schema(Api::V1::PeriodRepresenter, include: :readable)}
  EOS
  def restore
    period_model = @period.to_model
    return render_api_errors(period_model.errors) unless period_model.valid?

    standard_restore(period_model, Api::V1::PeriodRepresenter)
  end

  private

  def find_period_and_course
    if params[:course_id]
      @course = CourseProfile::Models::Course.find(params[:course_id])
    elsif params[:id]
      @period = CourseMembership::GetPeriod[id: params[:id]]
      @course = @period.course
    end
  end
end
