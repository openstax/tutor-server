module Api::V1::FakePurchaseActions
  def self.included(base)
    base.class_exec do
      api :POST, '/fake', 'Adds fake purchased items to Tutor'
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
        uuids.each{|uuid| OpenStax::Payments::FakePurchasedItem.create(uuid: uuid)}
        head :ok
      end
    end
  end
end
