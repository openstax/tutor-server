module Manager::StudentActions
  def self.included(base)
    base.before_action :get_course, only: [:index]
  end

  def index
    @students = GetCourseRoster.call(course: @entity_course).outputs.roster[:students]
    @students.sort! { |a, b| a.username <=> b.username }
    render 'manager/students/index'
  end

  protected

  def get_course
    @entity_course = Entity::Course.find(params[:course_id])
    @course = GetCourseProfile[course: @entity_course]
  end
end
