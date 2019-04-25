class Api::V1::RolesController < Api::V1::ApiController

  before_filter :get_role

  resource_description do
    api_versions "v1"
    short_description 'Represents a teacher preview student in a course period'
    description <<-EOS
      Teacher students allow teachers to preview student assignments.
    EOS
  end

  api :PUT, '/roles/:id/become', 'Become the role with the specified id'
  description 'Become the role with the specified id'
  def become
    OSU::AccessPolicy.require_action_allowed!(:become, current_human_user, @role)

    session[:role_id] = @role.id
  end

  protected

  def get_role
    @role = Entity::Role.find(params[:id])
  end

end
