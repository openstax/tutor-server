class Api::V1::LmsController < Api::V1::ApiController

  before_filter :get_course


  resource_description do
    api_versions "v1"
    short_description 'Get secrets for LMS'
    description <<-EOS
    EOS
  end

  api :GET, '/terms', 'Returns info on to connect a course to a LMS system'
  description <<-EOS
    TODO
  EOS
  def index
    if @course.blank? || !UserIsCourseTeacher[user: current_human_user, course: @course]
      head :forbidden and return
    end

    # TODO: use polymorphic belongs to?
    condition = { owner_id: @course.id, name: @course.name }
    consumer = Lms::Models::ToolConsumer.where(condition).first || Lms::Models::ToolConsumer.create(condition)
    render json: consumer.as_json.merge(
             url: lms_configuration_url,
             xml: render_to_string(template: 'lms/configuration.xml')
           )
  end

  protected

  def get_course
    @course = CourseProfile::Models::Course.find(params[:course_id])
  end

end
