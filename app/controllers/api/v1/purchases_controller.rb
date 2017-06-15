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
    if PurchasedItem.exists?(uuid: params[:id])
      UpdatePaymentStatus.perform_later(uuid: params[:id])
      head :accepted
    else
      head :not_found
    end
  end

  if !IAm.real_production?
    api :POST, 'fake', 'Adds fake purchased items to Tutor'
    description <<-EOS
      Adds fake purchased items to Tutor for testing.  In the posted data, include
      JSON with an array of UUIDs for the items.  These correspond to the product
      instance UUIDs on Payments.  Should always return 200.

          curl -i -X PUT http://localhost:3001/api/purchases/2f25f315-137f-4ec2-9efe-d23cdb70501e/check
          => 404 Not Found
          curl -i -H "Content-Type: application/json" -X POST -d '["2f25f315-137f-4ec2-9efe-d23cdb70501e","f030e182-0985-4a6e-a54f-7d1dc0230eb0"]' http://localhost:3001/api/purchases/fake
          => 200 OK
          curl -i -X PUT http://localhost:3001/api/purchases/2f25f315-137f-4ec2-9efe-d23cdb70501e/check
          => 202 Accepted
    EOS
    def create_fake
      uuids = JSON.parse(request.body.read)
      uuids.each{|uuid| OpenStax::Payments::FakePurchasedItem.create(uuid)}
      head :ok
    end
  end

end
