require 'rails_helper'

RSpec.describe Api::V1::UserRepresenter, type: :representer do
  let(:user)           { FactoryBot.create(:user_profile) }
  let(:representation) { Api::V1::UserRepresenter.new(user).as_json }

  it 'generates a JSON representation of a user' do
    expect(representation['name']).to eq user.name
    expect(representation['first_name']).to eq user.first_name
    expect(representation['last_name']).to eq user.last_name
    expect(representation['is_admin']).to eq user.is_admin?
    expect(representation['is_customer_service']).to eq user.is_customer_support?
    expect(representation['is_content_analyst']).to eq user.is_content_analyst?
    expect(representation['is_researcher']).to eq user.is_researcher?
    expect(representation['self_reported_role']).to eq user.role
    expect(representation['faculty_status']).to eq user.faculty_status
    expect(representation['can_create_courses']).to eq user.can_create_courses?
    expect(representation['viewed_tour_stats']).to eq []
    expect(representation['available_terms']).to eq []
    expect(representation['profile_url']).to eq Addressable::URI.join(
      OpenStax::Accounts.configuration.openstax_accounts_url, '/profile'
    ).to_s
  end

  it 'includes viewed tour ids' do
    User::RecordTourView[user: user, tour_identifier: 'chaos-fang']
    expect(representation['viewed_tour_stats']).to eq [{'id' => 'chaos-fang', 'view_count' => 1}]
  end

  it 'flags terms as needing signing' do
    user # force let to fire before create contract

    FinePrint::Contract.create! do |contract|
      contract.name    = 'general_terms_of_use'
      contract.version = 1
      contract.title   = 'Terms of Use'
      contract.content = 'Placeholder for general terms of use, required for new installations to function'
    end

    expect(representation).to include('available_terms' => true)
  end
end
