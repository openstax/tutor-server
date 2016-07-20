require 'rails_helper'

RSpec.describe Api::V1::BootstrapDataRepresenter, type: :representer do

  let(:user)           { FactoryGirl.create(:user) }
  let(:representation) do
    described_class.new(user).to_json(
      user_options: {
        tutor_notices_url: 'https://example.com/notices',
        flash: { alert: 'Nothing!'}
      }
    )
  end

  it "generates a JSON representation of data for a user to start work with" do
    expect(JSON.parse representation).to eq(
      "user" =>  Api::V1::UserRepresenter.new(user).as_json,
      "courses" => [], # not testing this since it's too expensive to generate meaningful course data
      "base_accounts_url" => OpenStax::Accounts.configuration.openstax_accounts_url,
      "accounts_profile_url" => OpenStax::Accounts.configuration.openstax_accounts_url + 'profile',
      "tutor_notices_url" => 'https://example.com/notices',
      "flash" => { "alert" => 'Nothing!' }
    )
  end

end
