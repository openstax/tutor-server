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

  api :POST, '/ui-settings', 'Save settings about the currently logged in user'
  description <<-EOS
    Saves the user interface settigs for the current user.
    The front-end of the application uses this endpoint to save various non-critical settings
    related to how the interface should behave based on actions the user has performed
    Returns header forbidden (403) if the user is not logged in or api_errors if the update fails.
  EOS
  def ui_settings
    standard_update(current_human_user.to_model, Api::V1::UiSettingsRepresenter, location: nil)
  end

end
