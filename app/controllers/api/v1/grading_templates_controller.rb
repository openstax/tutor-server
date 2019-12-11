class Api::V1::GradingTemplatesController < Api::V1::ApiController
  resource_description do
    api_versions 'v1'
    short_description 'Represents grading templates for the course'
    description <<~DESCRIPTION
      Grading templates determine how assignments are graded in the course
    DESCRIPTION
  end

  api :GET, '/courses/1/grading_templates', 'Returns all grading templates for the given course'
  description <<~DESCRIPTION
    Returns all grading templates for the given course
    #{json_schema(Api::V1::GradingTemplateRepresenter, include: :readable)}
  DESCRIPTION
  def index
    standard_index course.grading_templates.preload(:course), Api::V1::GradingTemplateRepresenter
  end

  api :POST, '/courses/1/grading_templates', 'Creates a new grading template for the given course'
  description <<~DESCRIPTION
    Creates a new grading template for the given course
    #{json_schema(Api::V1::GradingTemplateRepresenter, include: :writeable)}
  DESCRIPTION
  def create
    standard_nested_create Tasks::Models::GradingTemplate.new,
                           :course,
                           course,
                           Api::V1::GradingTemplateRepresenter
  end

  api :PATCH, '/grading_templates/1', 'Updates the given grading template'
  description <<~DESCRIPTION
    Updates the given grading template
    #{json_schema(Api::V1::GradingTemplateRepresenter, include: :writeable)}
  DESCRIPTION
  def update
    standard_update Tasks::Models::GradingTemplate.find(params[:id]),
                    Api::V1::GradingTemplateRepresenter
  end

  api :DELETE, '/grading_templates/1', 'Deletes the given grading template'
  description <<~DESCRIPTION
    Deletes the given grading template
    #{json_schema(Api::V1::GradingTemplateRepresenter, include: :readable)}
  DESCRIPTION
  def destroy
    standard_destroy Tasks::Models::GradingTemplate.find(params[:id]),
                     Api::V1::GradingTemplateRepresenter
  end

  protected

  def course
    @course ||= CourseProfile::Models::Course.find params[:course_id]
  end
end
