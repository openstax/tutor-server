class Api::V1::UsersController < Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'Represents a user in the system'
    description <<-EOS
      User description to be written...
    EOS
  end

  api :GET, '/user', 'Returns information about the currently logged in user'
  description <<-EOS
    If requested by a session/OAuth user,
    returns a JSON object containing only information that the user should be able to view.
    Otherwise returns header forbidden (403).
    #{json_schema(Api::V1::UserRepresenter, include: :readable)}
  EOS
  def show
    if current_human_user.nil? || current_human_user.is_anonymous?
      head :forbidden
    else
      respond_with current_human_user, represent_with: Api::V1::UserRepresenter
    end
  end

end
