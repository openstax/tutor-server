class OpenStax::Payments::FakePurchasedItem

  attr_reader :uuid
  attr_accessor :is_paid

  def self.find(uuid)
    data = store.get(key(uuid))
    return nil if data.nil?
    data = JSON.parse(data)
    new(uuid: data['uuid'], is_paid: data['is_paid'])
  end

  def self.find!(uuid)
    find(uuid) || new(uuid: uuid)
  end

  def self.create(uuid: SecureRandom.uuid, is_paid: false)
    raise "already exists" if find(uuid).present?
    new(uuid: uuid, is_paid: is_paid).tap(&:save)
  end

  def save
    self.class.store.set(self.class.key(uuid), {uuid: uuid, is_paid: is_paid}.to_json)
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

  protected

  def initialize(uuid:, is_paid: false)
    @uuid = uuid
    @is_paid = is_paid
  end

end
