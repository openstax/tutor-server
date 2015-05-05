class Api::V1::UsersController < Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'Represents a user in the system'
    description <<-EOS
      User description to be written...
    EOS
  end

  api :GET, '/user', <<-EOS
    If requested by a session/OAuth user, returns a JSON object containing only the users name.
    Otherwise returns header forbidden (403).
  EOS
  def show
    if current_human_user.nil? || current_human_user.is_anonymous?
      head :forbidden
    else
      render json: { name: current_human_user.name }
    end
  end

end
