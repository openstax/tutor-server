require 'rails_helper'

RSpec.describe Api::V1::UserRepresenter, type: :representer do


  let(:user)           { FactoryGirl.create(:user) }
  let(:representation) { Api::V1::UserRepresenter.new(user).as_json }

  it 'generates a JSON representation of a user' do
    expect(representation['name']).to eq user.name
    expect(representation['is_admin']).to eq user.is_admin?
    expect(representation['is_customer_service']).to eq user.is_customer_service?
    expect(representation['is_content_analyst']).to eq user.is_content_analyst?
    expect(representation['faculty_status']).to eq user.faculty_status
    expect(representation['profile_url']).to eq Addressable::URI.join(
      OpenStax::Accounts.configuration.openstax_accounts_url, '/profile'
    ).to_s
  end

end
