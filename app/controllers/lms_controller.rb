class LmsController < ApplicationController

  skip_before_filter :verify_authenticity_token, only: [:launch, :ci_launch]
  skip_before_filter :authenticate_user!, only: [:configuration, :launch, :launch_authenticate, :ci_launch]

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
    rescue Lms::Launch::Error => ee
      render :launch_failed
    end
  end

  def launch_authenticate
    begin
      launch = Lms::Launch.from_id(session[:launch_id])

      # Always send users to accounts when a launch happens.  We may decide
      # later to skip accounts when the user is already logged in, but in
      # that case we will want to make sure that the launching user is in
      # fact the user who is logged in, for which we'd need to track a link
      # between LMS user ID and local user ID.  For users who have launched
      # before, the trip to Accounts and back should be pretty quick / invisible.

      redirect_to openstax_accounts.login_url(
        sp: OpenStax::Api::Params.sign(
          params: {
            uuid:  launch.lms_user_id,
            name:  launch.full_name,
            email: launch.email,
            school: launch.school,
            role:  launch.role
          },
          secret: OpenStax::Accounts.configuration.openstax_application_secret
        ),
        return_to: lms_complete_launch_url
      )
    rescue Lms::Launch::Error => ee
      render :launch_failed
    end
  end

  def complete_launch
    launch = Lms::Launch.from_id(session.delete(:launch_id))

    handle_with(LmsCompleteLaunch,
                launch: launch,
                success: lambda do
                  if @handler_result.outputs.is_unenrolled_student
                    redirect_to token_enroll_url(@handler_result.outputs.course.uuid)
                  else
                    redirect_to course_dashboard_url(@handler_result.outputs.course)
                  end
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

end
