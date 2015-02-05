require 'rails_helper'

describe CreateUser do
  let!(:account) { FactoryGirl.create(:openstax_accounts_account) }

  before(:each) do
    OpenStax::Exchange::FakeClient.configure do |config|
      config.registered_platforms   = {
        OpenStax::Exchange.configuration.client_platform_id =>
        OpenStax::Exchange.configuration.client_platform_secret
      }
      config.server_url             = OpenStax::Exchange.configuration.client_server_url
      config.supported_api_versions = [OpenStax::Exchange.configuration.client_api_version]
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

  context "when account is nil" do
    it "returns an outcome with errors" do
      outcome = CreateUser.call(nil)
      expect(outcome.errors).to_not be_empty
    end
  end

  context "when exchange_identifier is not set" do
    before(:each) do
      OpenStax::Exchange::FakeClient.configure do |config|
        config.server_url = 'https://some.fake.address'
      end
      OpenStax::Exchange.reset!
    end

    it "returns an error" do
      expect(CreateUser.call(account).errors).not_to be_empty
    end

    it "does not create a new User" do
      expect {
        begin
          CreateUser.call(account)
        rescue
        end
      }.to change{User.count}.by 0
    end
  end
end
