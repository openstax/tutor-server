require 'rails_helper'

RSpec.describe Api::V1::BootstrapDataRepresenter, type: :representer do

  let(:user)           { FactoryGirl.create(:user) }
  let(:representation) { described_class.new(user).as_json }

  it "generates a JSON representation of data for a user to start work with" do
    expect(representation).to eq(
      "user" =>  Api::V1::UserRepresenter.new(user).as_json,
      "courses" => [], # not testing this since it's too expensive to generate meaningful course data
      "base_accounts_url" => OpenStax::Accounts.configuration.openstax_accounts_url,
      "accounts_profile_url" => OpenStax::Accounts.configuration.openstax_accounts_url + 'profile',
      "accounts_user_url" => OpenStax::Accounts.configuration.openstax_accounts_url + 'api/user'
    )
  end

end
