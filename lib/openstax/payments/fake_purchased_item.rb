class OpenStax::Payments::FakePurchasedItem

  attr_reader :uuid

  def initialize(uuid:)
    @uuid = uuid
  end

  def self.find(uuid)
    store.get(key(uuid)).present? ? new(uuid: uuid) : nil
  end

  def self.create(uuid)
    store.set(key(uuid), 1)
  end

  def self.key(uuid)
    "fake_purchased_item:#{uuid}"
  end

  def self.store
    @store ||= begin
      redis_secrets = Rails.application.secrets['redis']
      Redis::Store.new(
        url: redis_secrets['url'],
        namespace: redis_secrets['namespaces']['fake_payments']
      )
    end
  end

end
