class OpenStax::Payments::Api::FakeClient

  attr_reader :store

  def initialize(configuration)
    @store = configuration.fake_store
  end

  def reset!
    store.clear
  end

  def name
    :fake
  end

  def orders_for_account(account)
    {
      orders: [
        {:product_instance_uuid=>"e0e53852-541e-449b-acf1-0335c5183740", :total=>"13.41", :sales_tax=>"1.08", :is_refunded=>false, :purchased_at=>"2017-07-13T22:58:30.929412+00:00", :updated_at=>"2017-07-13T22:58:30.929412+00:00", :product=>{:uuid=>"e6d22dbc-0a01-5131-84ba-2214bbe4d74d", :name=>"OpenStax Tutor", :price=>"12.33"}},
        {:product_instance_uuid=>"06fc16fc-70f5-4db1-a61d-b0f496cf3cd4", :total=>"13.41", :sales_tax=>"1.08", :is_refunded=>false, :purchased_at=>"2017-07-13T23:09:11.996562+00:00", :updated_at=>"2017-07-13T23:09:11.996562+00:00", :product=>{:uuid=>"e6d22dbc-0a01-5131-84ba-2214bbe4d74d", :name=>"OpenStax Tutor", :price=>"12.33"}}
      ]
    }
  end

  def check_payment(product_instance_uuid:)
    # TODO check @store to see if product exists
    {
      paid: false,
      purchased_at: Time.now
    }
  end

  def refund(product_instance_uuid:)
    # TODO check @store to see if product exists, update it, call check_payment
    {
      success: true,
      transaction_uuid: fake_braintree_transaction_id
    }
  end

  if !IAm.real_production?
    def fake_pay(product_instance_uuid:)

    end
  end

  def fake_braintree_transaction_id
    "fake_bt_transaction_#{SecureRandom.uuid[0..5]}"
  end

end
