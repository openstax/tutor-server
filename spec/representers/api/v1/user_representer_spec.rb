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
    expect(representation['viewed_tour_ids']).to eq []
    expect(representation['terms_signatures_needed']).to eq false
    expect(representation['profile_url']).to eq Addressable::URI.join(
      OpenStax::Accounts.configuration.openstax_accounts_url, '/profile'
    ).to_s
  end

  it 'includes viewed tour ids' do
    User::RecordTourView[user: user, tour_identifier: 'chaos-fang']
    expect(representation['viewed_tour_ids']).to eq ['chaos-fang']
  end

  it "flags terms as needing signing" do
    user # force let to fire before create contract

    FinePrint::Contract.create! do |contract|
      contract.name    = 'general_terms_of_use'
      contract.version = 1
      contract.title   = 'Terms of Use'
      contract.content = 'Placeholder for general terms of use, required for new installations to function'
    end

    expect(representation).to include(
      "terms_signatures_needed" => true
    )
  end

end
