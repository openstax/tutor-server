class LmsController < ApplicationController

  skip_before_filter :verify_authenticity_token, only: [:launch, :ci_launch]
  skip_before_filter :authenticate_user!, only: [:configuration, :launch, :ci_launch]

  before_filter :allow_embedding_in_iframe, only: [:launch, :ci_launch]

  layout false

  def configuration; end

  def launch
    begin
      launch = Lms::Launch.from_request(request)

      Rails.logger.debug { launch.formatted_data(include_everything: true) }

      # Bail early if we can't handle the launch role
      if !(launch.is_student? || launch.is_instructor?)
        render(:unsupported_role) and return
      end

      # Persist the launch so we can load it after return from Accounts
      session[:launch_id] = launch.persist!

      # Always send users to accounts when a launch happens.  We may decide
      # later to skip accounts when the user is already logged in, but in
      # that case we will want to make sure that the launching user is in
      # fact the user who is logged in, for which we'd need to track a link
      # between LMS user ID and local user ID.  For users who have launched
      # before, the trip to Accounts and back should be pretty quick / invisible.

      send_launched_user_to_accounts(launch)
    rescue Lms::Launch::Error
      render :launch_failed
    end
  end

  def complete_launch
    launch = Lms::Launch.from_id(session.delete(:launch_id))

    handle_with(LmsCompleteLaunch,
                launch: launch,
                success: lambda do
                  render :complete_launch,
                         locals: {
                           destination_url: course_dashboard_url(outputs.course)
                         }
                end,
                failure: lambda do
                  render :launch_failed
                end)
  end

  def ci_launch
    begin
      @launch = Lms::Launch.from_request(request)
    rescue Lms::Launch::Error
      redirect_to action: :launch_failed
    end
  end

  protected

  def allow_embedding_in_iframe
    response.headers["X-FRAME-OPTIONS"] = 'ALLOWALL'
  end

  def send_launched_user_to_accounts(launch)
    redirect_to openstax_accounts.login_url(
      sp: OpenStax::Api::Params.sign(
        params: {
          uuid:  launch.lms_user_id,
          name:  launch.full_name,
          email: launch.email,
          role:  launch.role
        },
        secret: Rails.application.secrets.openstax['accounts']['secret']
      ),
      go: 'trusted_launch',
      return_to: lms_complete_launch_url
    )
  end

end
