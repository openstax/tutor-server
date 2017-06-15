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
    {
      paid: false,
      changed_at: Time.now
    }
  end

end
