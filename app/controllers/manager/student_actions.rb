module Manager::StudentActions
  def self.included(base)
    base.before_action :get_course, only: [:index]
  end

  def index
    @students = GetCourseRoster.call(course: @course).outputs.roster[:students]
                  .sort{ |a, b| a.name <=> b.name }
    render 'manager/students/index'
  end

  protected

  def get_course
    @course = CourseProfile::Models::Course.find(params[:course_id])
  end
end
