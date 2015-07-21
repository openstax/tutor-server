class Admin::StudentsController < Admin::BaseController
  before_action :get_course, only: [:index]

  def index
    @students = GetStudentRoster[course: @entity_course]
    @students.sort! { |a, b| a.username <=> b.username }
  end

  protected

  def get_course
    @entity_course = Entity::Course.find(params[:course_id])
    @course = GetCourseProfile[course: @entity_course]
  end
end
