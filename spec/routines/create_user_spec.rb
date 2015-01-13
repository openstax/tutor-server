require 'rails_helper'

describe CreateUser do
  let!(:account) { FactoryGirl.create(:openstax_accounts_account) }

  before(:each) do
    OpenStax::Exchange.configure do |config|
      config.client_platform_id     = '123'
      config.client_platform_secret = 'abc'
      config.client_server_url      = 'https://exchange.openstax.org'
      config.client_api_version     = 'v1'
    end

    OpenStax::Exchange::FakeClient.configure do |config|
      config.registered_platforms   = { '123' => 'abc'}
      config.server_url             = 'https://exchange.openstax.org'
      config.supported_api_versions = ['v1']
    end

    OpenStax::Exchange.use_fake_client
    OpenStax::Exchange.reset!
  end

  context "success" do
    it "creates a new User" do
      expect {
        CreateUser.call(account)
      }.to change{User.count}.by 1
    end
    it "initializes the User's exchange_identifier" do
      outcome = CreateUser.call(account)
      expect(outcome.outputs[:user].exchange_identifier).to match(/^[a-fA-F0-9]+$/)
    end
    it "returns an outcome without errors" do
      outcome = CreateUser.call(account)
      expect(outcome.errors).to be_empty
    end
  end

  context "when account is not passed in" do
    it "raises an exception" do
      expect {
        outcome = CreateUser.call()
      }.to raise_error
    end
  end

  context "when exchange_identifier is not set" do
    before(:each) do
      OpenStax::Exchange::FakeClient.configure do |config|
        config.server_url = 'https://some.fake.address'
      end
      OpenStax::Exchange.reset!
    end

    it "does not create a new User" do
      expect {
        CreateUser.call(account)
      }.to change{User.count}.by 0
    end
    it "returns an outcome with errors" do
      outcome = CreateUser.call(account)
      expect(outcome.errors).to_not be_empty
    end
  end
end
