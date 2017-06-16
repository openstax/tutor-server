class Api::V1::PurchasesController < Api::V1::ApiController
  resource_description do
    api_versions "v1"
    short_description 'Interface for purchases'
    description <<-EOS
    EOS
  end

  api :PUT, ':id/check', 'Instructs Tutor to check on a purchase\'s payment status'
  description <<-EOS
    Instructs Tutor to check on a purchase\'s payment status.  The ID is the UUID
    of the purchase.  This endpoint is throttled.

    Responses:
    * 202 Accepted if all good
    * 404 if the UUID does not exist for a purchase
    * 429 if throttled
    * 5xx if things go boom

    Caller should retry later if response is not 2xx or 404.
  EOS
  def check
    # Stubbed for now
    if CourseMembership::Models::Student.find_by(uuid: params[:id])
      # TODO Call background job to do the check callback to payments
      head :accepted
    else
      head :not_found
    end
  end

end
