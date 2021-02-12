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


  api :GET, '/bootstrap', 'Returns initial of data application needs to start up'
  description <<-EOS
    Includes user information, current courses, and terms of use.
    #{json_schema(Api::V1::BootstrapDataRepresenter, include: :readable)}
  EOS
  def bootstrap
    if current_human_user.nil? || current_human_user.is_anonymous?
      head :forbidden
    else
      respond_with current_human_user,
                   represent_with: Api::V1::BootstrapDataRepresenter,
                   user_options: {
                     tutor_api_url: api_root_url,
                     flash: flash.to_hash,
                     is_impersonating: session[:admin_user_id].present?
                   }
    end
  end


  api :PUT, '/ui-settings', 'Save settings about the currently logged in user'
  description <<-EOS
    Saves the user interface settigs for the current user.
    The front-end of the application uses this endpoint to save various non-critical settings
    related to how the interface should behave based on actions the user has performed
    Returns header forbidden (403) if the user is not logged in or api_errors if the update fails.
  EOS
  def ui_settings
    standard_update(current_human_user, Api::V1::UiSettingsRepresenter, location: nil)
  end


  api :PUT, '/tours', 'Save the "viewed" status of a given tour'
  description <<-EOS
    Marks a given tour as watched.
    The tour identifier is a simple string that is generated by the js front-end application.
    No validation is performed on it other than ensureing it's alphabetical without spaces
    If the tour has already been seen, the viewed count is incremented.
    Returns header forbidden (403) if the user is not logged in or api_errors if the update fails.
    If requests succeeds, an empty JSON object is returned
  EOS
  def record_tour_view
    result = User::RecordTourView.call(user: current_human_user, tour_identifier: params[:tour_id])
    render_api_errors(result.errors) || head(:no_content)
  end

  api :POST, '/suggest'
  description <<-EOS
    Saves a user suggestion. The current default only supports teachers suggesting subjects.
  EOS
  def suggest
    OSU::AccessPolicy.require_action_allowed!(:create, current_human_user, User::Models::Suggestion)

    User::Models::Suggestion.create(profile: current_human_user, content: params[:data])
    head :ok
  end
end
