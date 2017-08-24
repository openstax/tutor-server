class Api::V1::LmsController < Api::V1::ApiController

  before_filter :get_course

  resource_description do
    api_versions "v1"
    short_description 'Get secrets for LMS'
    description <<-EOS
    EOS
  end

  api :GET, '/lms', 'Returns info on to connect a course to a LMS system'
  description <<-EOS
    TODO
  EOS
  def index
    if @course.blank? || !UserIsCourseTeacher[user: current_human_user, course: @course]
      head :forbidden and return
    end

    app = Lms::Models::App.find_or_create_by(owner: @course)

    render json: app.as_json.merge(
             url: lms_configuration_url(format: :xml),
             xml: render_to_string(template: 'lms/configuration.xml')
           )
  end

  protected

  def get_course
    @course = CourseProfile::Models::Course.find(params[:course_id])
  end

end
