class Api::V1::RolesController < Api::V1::ApiController

  before_filter :get_role

  resource_description do
    api_versions "v1"
    short_description 'Represents a teacher preview student in a course period'
    description <<-EOS
      Teacher students allow teachers to preview student assignments.
    EOS
  end

  api :PUT, '/roles/:id/become', 'Become the specified role in its course'
  description <<-EOS
    Become the specified role when accessing its course

    The role must belong to the calling user
  EOS
  def become
    OSU::AccessPolicy.require_action_allowed!(:become, current_human_user, @role)

    course = case @role.role_type.to_sym
    when :teacher
      @role.teacher.course
    when :student
      @role.student.course
    when :teacher_student
      @role.teacher_student.course
    else
      render json: {
        errors: [ { code: 'invalid_role', message: 'You cannot become the specified role' } ]
      }, status: :unprocessable_entity

      return
    end

    session[:roles] ||= {}
    session[:roles][course.id.to_s] = @role.id

    respond_with(
      @role,
      represent_with: Api::V1::RoleRepresenter,
      responder: ResponderWithPutPatchDeleteContent
    )
  end

  protected

  def get_role
    @role = Entity::Role.find(params[:id])
  end

end
