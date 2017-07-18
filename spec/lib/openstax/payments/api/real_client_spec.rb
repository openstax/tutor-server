require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Payments::Api::RealClient, type: :external, vcr: VCR_OPTS do

  set_vcr_config_around(:all, ignore_localhost: false)

  before(:all) do
    @config = OpenStax::Payments::Api.configuration
    @uuids = vcr_friendly_uuids(count: 10, namespace: "payments_real_client")
  end

  # TODO filter keys from cassettes

  subject(:real_client) { described_class.new(@config) }

  context '#check_payment' do
    it 'raises an error for non-existent product instances' do
      expect{
        real_client.check_payment(product_instance_uuid: @uuids.shift)
      }.to raise_error(OpenStax::Payments::RemoteError, /404/)
    end

    it 'returns status when product instance exists' do
      uuid = @uuids.shift
      make_purchase(product_instance_uuid: uuid)
      response = real_client.check_payment(product_instance_uuid: uuid)
      expect(response[:paid]).to eq true
    end
  end

  context '#refund' do
    it 'raises an error for non-existent product instances' do
      expect{
        real_client.refund(product_instance_uuid: @uuids.shift)
      }.to raise_error(OpenStax::Payments::RemoteError, /404/)
    end

    it 'succeeds when purchased product instance exists' do
      uuid = @uuids.shift
      make_purchase(product_instance_uuid: uuid)
      response = real_client.refund(product_instance_uuid: uuid)
      expect(response[:success]).to eq true
    end

    it 'gets unpaid status after a refund' do
      uuid = @uuids.shift
      make_purchase(product_instance_uuid: uuid)
      rr = real_client.refund(product_instance_uuid: uuid)
      response = real_client.check_payment(product_instance_uuid: uuid)
      expect(response[:paid]).to eq false
    end
  end

  context '#orders_for_account' do
    it 'returns empty array for invalid uuids' do
      fake_account = Hashie::Mash.new(uuid: @uuids.shift)
      response = real_client.orders_for_account(fake_account)
      expect(response[:orders]).to be_empty
    end

    it 'fetches orders for a user' do
      uuid = @uuids.shift
      make_purchase(purchaser_account_uuid: uuid)
      account = Hashie::Mash.new(uuid: uuid)
      response = real_client.orders_for_account(account)
      expect(response[:orders]).not_to be_empty
    end
  end

  def make_purchase(product_instance_uuid: nil, purchaser_account_uuid: nil)
    response = real_client.make_fake_purchase(
      product_instance_uuid: product_instance_uuid,
      purchaser_account_uuid: purchaser_account_uuid
    )
    expect(response[:success]).to eq(true), "make_purchase failed: #{response}"
  end

end
