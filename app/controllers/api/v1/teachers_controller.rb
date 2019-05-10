class Api::V1::TeachersController < Api::V1::ApiController
  before_action :get_teacher, only: [:destroy]

  resource_description do
    api_versions 'v1'
    short_description 'Represents a teacher in a course'
    description <<-EOS
      Other teachers and admins are allowed to create and remove teachers from a course.
    EOS
  end

  api :DELETE, '/teachers/:teacher_id', 'Removes a teacher from the course'
  description <<-EOS
    Removes a teacher from the course.

    #{json_schema(Api::V1::TeacherRepresenter, include: :readable)}
  EOS
  def destroy
    OSU::AccessPolicy.require_action_allowed!(:destroy, current_api_user, @teacher)
    standard_destroy(@teacher, Api::V1::TeacherRepresenter)
  end

  protected

  def get_teacher
    @teacher = CourseMembership::Models::Teacher.find(params[:id])
  end

end
