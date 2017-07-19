require_relative './fake_purchase_actions'

class Api::V1::PurchasesController < Api::V1::ApiController

  before_filter :verify_purchase_exists, only: [:check, :refund]

  resource_description do
    api_versions "v1"
    short_description 'Interface for purchases'
    description <<-EOS
    EOS
  end

  api :PUT, '/purchases/:id/check', 'Instructs Tutor to check on a purchase\'s payment status'
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
    UpdatePaymentStatus.perform_later(uuid: params[:id])
    head :accepted
  end

  api :PUT, '/purchases/:id/refund', 'Instructs Tutor to initiate a refund of this purchase'
  description <<-EOS
    Instructs Tutor to initate a refund of this purchase.  The ID is the UUID of the
    purchase.

    Responses:
    * 202 Accepted if all good
    * 404 if the UUID does not exist for a purchase
    * 422 with code 'not_paid' if the purchase hasn't been paid yet
    * 422 with code 'refund_period_elapsed' if the refund was requested too late
    * 5xx if things go boom
  EOS
  def refund
    OSU::AccessPolicy.require_action_allowed!(:refund, current_api_user, purchased_item)

    if purchased_item.is_a?(CourseMembership::Models::Student)
      return render_api_errors(:not_paid) if !purchased_item.is_paid
      return render_api_errors(:refund_period_elapsed) if !purchased_item.is_refund_allowed
    end

    RefundPayment.perform_later(uuid: params[:id], survey: params[:survey])
    head :accepted
  end

  api :GET, '/purchases', 'Instructs Tutor to fetch the list of purchase\'s for a user'
  description <<-EOS
    Instructs Tutor to retreive the list of purchases for a user
  EOS
  def index
    response = OpenStax::Payments::Api.orders_for_account(current_human_user.account)
    render json: response, status: :ok
  end

  include Api::V1::FakePurchaseActions if !IAm.real_production?

  protected

  def purchased_item
    @purchased_item ||= PurchasedItem.find(uuid: params[:id])
  end

  def verify_purchase_exists
    head(:not_found) if purchased_item.nil?
  end

end
