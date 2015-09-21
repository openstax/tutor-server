require 'rails_helper'

RSpec.describe UserProfile::SearchProfiles, type: :routine do
  let!(:admin) { FactoryGirl.create :user_profile_profile,
                                    :administrator,
                                    username: 'admin',
                                    first_name: 'Administrator',
                                    last_name: 'User',
                                    full_name: 'Administrator User' }
  let!(:profile_1) { FactoryGirl.create :user_profile_profile,
                                        username: 'student',
                                        first_name: 'Chris',
                                        last_name: 'Mass',
                                        full_name: 'Chris Mass' }
  let!(:profile_2) { FactoryGirl.create :user_profile_profile,
                                        username: 'teacher',
                                        first_name: 'Stan',
                                        last_name: 'Dup',
                                        full_name: 'Stan Dup' }

  it 'searches username and name' do
    results = described_class[search: '%ch%']
    expect(results.total_items).to eq 2
    expect(results.items).to eq [ {
      'id' => profile_2.id,
      'account_id' => profile_2.account.id,
      'entity_user_id' => profile_2.entity_user_id,
      'full_name' => 'Stan Dup',
      'name' => 'Stan Dup',
      'username' => 'teacher'
    }, {
      'id' => profile_1.id,
      'account_id' => profile_1.account.id,
      'entity_user_id' => profile_1.entity_user_id,
      'full_name' => 'Chris Mass',
      'name' => 'Chris Mass',
      'username' => 'student'
    } ]
  end

  it 'paginates results' do
    results = described_class[search: '%', per_page: 2, page: 1]
    expect(results.total_items).to eq 3
    expect(results.items).to eq [ {
      'id' => profile_2.id,
      'account_id' => profile_2.account.id,
      'entity_user_id' => profile_2.entity_user_id,
      'full_name' => 'Stan Dup',
      'name' => 'Stan Dup',
      'username' => 'teacher'
    }, {
      'id' => profile_1.id,
      'account_id' => profile_1.account.id,
      'entity_user_id' => profile_1.entity_user_id,
      'full_name' => 'Chris Mass',
      'name' => 'Chris Mass',
      'username' => 'student'
    } ]

    results = described_class[search: '%', per_page: 2, page: 2]
    expect(results.total_items).to eq 3
    expect(results.items).to eq [ {
      'id' => admin.id,
      'account_id' => admin.account.id,
      'entity_user_id' => admin.entity_user_id,
      'full_name' => 'Administrator User',
      'name' => 'Administrator User',
      'username' => 'admin'
    } ]
  end

  it 'returns profiles for their entity users' do
    profiles = described_class[search: [admin.user, profile_1.user]]
    expect(profiles.total_items).to eq(2)
    expect(profiles.items).to eq [ {
      'id' => profile_1.id,
      'account_id' => profile_1.account.id,
      'entity_user_id' => profile_1.entity_user_id,
      'full_name' => 'Chris Mass',
      'name' => 'Chris Mass',
      'username' => 'student'
    }, {
      'id' => admin.id,
      'account_id' => admin.account.id,
      'entity_user_id' => admin.entity_user_id,
      'full_name' => 'Administrator User',
      'name' => 'Administrator User',
      'username' => 'admin'
    } ]
  end

  it 'requires that an array search is filled with entity users' do
    expect {
      described_class[search: [admin, profile_1]]
    }.to raise_error(TypeError,
                     "Tested argument was of class 'UserProfile::Models::Profile' instead of the expected 'Entity::User'.")
  end
end
