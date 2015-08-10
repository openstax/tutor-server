require 'rails_helper'

RSpec.describe UserProfile::SearchProfiles do
  let!(:admin) { FactoryGirl.create :user_profile,
                                    :administrator,
                                    username: 'admin',
                                    first_name: 'Administrator',
                                    last_name: 'User',
                                    full_name: 'Administrator User' }
  let!(:user_1) { FactoryGirl.create :user_profile,
                                     username: 'student',
                                     first_name: 'Chris',
                                     last_name: 'Mass',
                                     full_name: 'Chris Mass' }
  let!(:user_2) { FactoryGirl.create :user_profile,
                                     username: 'teacher',
                                     first_name: 'Stan',
                                     last_name: 'Dup',
                                     full_name: 'Stan Dup' }

  it 'searches username and name' do
    results = described_class[search: '%ch%']
    expect(results.total_items).to eq 2
    expect(results.items).to eq [ {
      'id' => user_2.id,
      'account_id' => user_2.account.id,
      'entity_user_id' => user_2.entity_user.id,
      'full_name' => 'Stan Dup',
      'name' => 'Stan Dup',
      'username' => 'teacher'
    }, {
      'id' => user_1.id,
      'account_id' => user_1.account.id,
      'entity_user_id' => user_1.entity_user.id,
      'full_name' => 'Chris Mass',
      'name' => 'Chris Mass',
      'username' => 'student'
    } ]
  end

  it 'paginates results' do
    results = described_class[search: '%', per_page: 2, page: 1]
    expect(results.total_items).to eq 3
    expect(results.items).to eq [ {
      'id' => user_2.id,
      'account_id' => user_2.account.id,
      'entity_user_id' => user_2.entity_user.id,
      'full_name' => 'Stan Dup',
      'name' => 'Stan Dup',
      'username' => 'teacher'
    }, {
      'id' => user_1.id,
      'account_id' => user_1.account.id,
      'entity_user_id' => user_1.entity_user.id,
      'full_name' => 'Chris Mass',
      'name' => 'Chris Mass',
      'username' => 'student'
    } ]

    results = described_class[search: '%', per_page: 2, page: 2]
    expect(results.total_items).to eq 3
    expect(results.items).to eq [ {
      'id' => admin.id,
      'account_id' => admin.account.id,
      'entity_user_id' => admin.entity_user.id,
      'full_name' => 'Administrator User',
      'name' => 'Administrator User',
      'username' => 'admin'
    } ]
  end

  it 'returns profiles for their entity users' do
    profiles = described_class[search: [admin.entity_user, user_1.entity_user]]
    expect(profiles.total_items).to eq(2)
    expect(profiles.items).to eq [ {
      'id' => user_1.id,
      'account_id' => user_1.account.id,
      'entity_user_id' => user_1.entity_user.id,
      'full_name' => 'Chris Mass',
      'name' => 'Chris Mass',
      'username' => 'student'
    }, {
      'id' => admin.id,
      'account_id' => admin.account.id,
      'entity_user_id' => admin.entity_user.id,
      'full_name' => 'Administrator User',
      'name' => 'Administrator User',
      'username' => 'admin'
    } ]
  end
end
