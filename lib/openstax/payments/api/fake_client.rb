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

  def check_payment(product_instance_uuid:)
    # TODO check @store to see if product exists
    {
      paid: false,
      changed_at: Time.now
    }
  end

  def initiate_refund(product_instance_uuid:)
    :ok
  end

  if !IAm.real_production?
    def fake_pay(product_instance_uuid:)

    end
  end

end
