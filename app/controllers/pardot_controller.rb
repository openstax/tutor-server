class PardotController < ApplicationController

  skip_before_action :authenticate_user!

  def toa
    # Fire off tracking background job and redirect user to the configurable
    # marketing page

    TrackTutorOnboardingEvent.perform_later(
      event: "arrived_tutor_marketing_page_from_pardot",
      user: current_user,
      data: {
        pardot_reported_contact_id: params[:sfc],
        pardot_reported_piaid: params[:piaid],
        pardot_reported_picid: params[:picid]
      }
    )

    if Settings::Pardot.toa_redirect.present?
      redirect_to Settings::Pardot.toa_redirect
    else
      raise "Pardot TOA redirect is not set! (if on prod, this is CRITICAL)"
    end
  end


end
