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
    [
      {:order_id=>78, :total=>"13.41", :sales_tax=>"1.08", :is_refunded=>false, :purchased_at=>"2017-07-13T22:58:30.929412+00:00", :updated_at=>"2017-07-13T22:58:30.929412+00:00", :product=>{:uuid=>"e6d22dbc-0a01-5131-84ba-2214bbe4d74d", :name=>"OpenStax Tutor", :price=>"12.33"}},
      {:order_id=>79, :total=>"13.41", :sales_tax=>"1.08", :is_refunded=>false, :purchased_at=>"2017-07-13T23:09:11.996562+00:00", :updated_at=>"2017-07-13T23:09:11.996562+00:00", :product=>{:uuid=>"e6d22dbc-0a01-5131-84ba-2214bbe4d74d", :name=>"OpenStax Tutor", :price=>"12.33"}}
    ]
  end

  def check_payment(product_instance_uuid:)
    # TODO check @store to see if product exists
    {
      paid: false,
      changed_at: Time.now
    }
  end

  def refund(product_instance_uuid:)
    :ok
  end

  if !IAm.real_production?
    def fake_pay(product_instance_uuid:)

    end
  end

end
