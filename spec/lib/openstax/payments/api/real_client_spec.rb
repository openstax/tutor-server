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

  context '#orders_for_account' do
    it 'returns empty array for invalid uuids' do
      fake_account = Hashie::Mash.new(uuid: SecureRandom.uuid)
      orders = real_client.orders_for_account(fake_account)
      expect(orders).to be_empty
    end
    it 'fetches orders for a user' do
      account = Hashie::Mash.new(uuid: 'c577b301-7696-46ba-bf27-503c6957750c')
      response = real_client.orders_for_account(account)
      expect(response[:orders]).not_to be_empty
      expect(response[:orders].first).to eq(:order_id=>78, :total=>"13.41", :sales_tax=>"1.08", :is_refunded=>false, :purchased_at=>"2017-07-13T22:58:30.929412+00:00", :updated_at=>"2017-07-13T22:58:30.929412+00:00", :product=>{:uuid=>"e6d22dbc-0a01-5131-84ba-2214bbe4d74d", :name=>"OpenStax Tutor", :price=>"12.33"})
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
      real_client.refund(product_instance_uuid: uuid)
      response = real_client.check_payment(product_instance_uuid: uuid)
      expect(response[:paid]).to eq false
    end
  end

  context '#orders_for_account' do
    it 'returns empty array for invalid uuids' do
      fake_account = Hashie::Mash.new(uuid: @uuids.shift)
      orders = real_client.orders_for_account(fake_account)
      expect(orders).to be_empty
    end

    it 'fetches orders for a user' do
      # TODO modify `make_purchase` (and mock_purchase on ospayments) to accept
      # a purchaser_account_uuid so that we can make fake purchases for a fake
      # purchaser and then query them here.  The test below relies on specific
      # test data existing in the payments server being tested.

      account = Hashie::Mash.new(uuid: 'c577b301-7696-46ba-bf27-503c6957750c')
      orders = real_client.orders_for_account(account)
      expect(orders).not_to be_empty
      expect(orders.first).to eq(:order_id=>78, :total=>"13.41", :sales_tax=>"1.08", :is_refunded=>false, :purchased_at=>"2017-07-13T22:58:30.929412+00:00", :updated_at=>"2017-07-13T22:58:30.929412+00:00", :product=>{:uuid=>"e6d22dbc-0a01-5131-84ba-2214bbe4d74d", :name=>"OpenStax Tutor", :price=>"12.33"})
    end
  end

  def make_purchase(product_instance_uuid:)
    response = real_client.make_fake_purchase(product_instance_uuid: product_instance_uuid)
    expect(response[:success]).to eq true
  end

end
