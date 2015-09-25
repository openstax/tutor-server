require 'rails_helper'

RSpec.describe Api::V1::UserRepresenter, type: :representer do


  let(:user)           {
    profile = FactoryGirl.create(:user_profile)
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  }
  let(:representation) { Api::V1::UserRepresenter.new(user).as_json }

  it "generates a JSON representation of a user" do
    expect(representation).to eq(
      "name" => user.name,
      'is_admin' => false,
      'is_customer_service' => false,
      'is_content_analyst' => false,
      'profile_url' => Addressable::URI.join(
        OpenStax::Accounts.configuration.openstax_accounts_url, '/profile'
      ).to_s
    )
  end

end
