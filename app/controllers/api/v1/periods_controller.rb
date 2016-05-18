class Api::V1::PeriodsController < Api::V1::ApiController
  before_filter :find_period_and_course

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
    period_model = CourseMembership::Models::Period.new
    CourseMembership::Models::Period.transaction do
      standard_nested_create(period_model, :course, @course, Api::V1::PeriodRepresenter)
      period = CourseMembership::Period.new(strategy: period_model.wrap)
      Tasks::AssignCoursewideTaskPlansToNewPeriod[period: period]
    end
  end

  api :PATCH, '/periods/:id', 'Returns an updated period for the given course'
  description <<-EOS
    #{json_schema(Api::V1::PeriodRepresenter, include: :readable)}
  EOS
  def update
    CourseMembership::Models::Period.transaction do
      standard_update(@period.to_model, Api::V1::PeriodRepresenter)
      SchoolDistrict::ProcessSchoolChange.call(course_profile: @period.course.profile)
    end
  end

  api :DELETE, '/periods/:id', 'Deletes a period for authorized teachers'
  def destroy
    standard_destroy(@period.to_model)
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
end
