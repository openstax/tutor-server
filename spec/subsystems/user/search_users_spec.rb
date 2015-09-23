require 'rails_helper'

RSpec.describe User::SearchUsers, type: :routine do
  let!(:admin) {
    profile = FactoryGirl.create :user_profile,
                                 :administrator,
                                 username: 'admin',
                                 first_name: 'Administrator',
                                 last_name: 'User',
                                 full_name: 'Administrator User'
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  }
  let!(:user_1) {
    profile = FactoryGirl.create :user_profile,
                                 username: 'student',
                                 first_name: 'Chris',
                                 last_name: 'Mass',
                                 full_name: 'Chris Mass'
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  }
  let!(:user_2) {
    profile = FactoryGirl.create :user_profile,
                                 username: 'teacher',
                                 first_name: 'Stan',
                                 last_name: 'Dup',
                                 full_name: 'Stan Dup'
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  }

  it 'searches username and name' do
    results = described_class[search: '%ch%']
    expect(results.total_items).to eq 2
    expect(results.items).to eq [ {
      'id' => user_2.id,
      'account_id' => user_2.account.id,
      'full_name' => 'Stan Dup',
      'name' => 'Stan Dup',
      'username' => 'teacher',
      'is_admin' => false,
      'is_content_analyst' => false
    }, {
      'id' => user_1.id,
      'account_id' => user_1.account.id,
      'full_name' => 'Chris Mass',
      'name' => 'Chris Mass',
      'username' => 'student',
      'is_admin' => false,
      'is_content_analyst' => false
    } ]
  end

  it 'paginates results' do
    results = described_class[search: '%', per_page: 2, page: 1]
    expect(results.total_items).to eq 3
    expect(results.items).to eq [ {
      'id' => user_2.id,
      'account_id' => user_2.account.id,
      'full_name' => 'Stan Dup',
      'name' => 'Stan Dup',
      'username' => 'teacher',
      'is_admin' => false,
      'is_content_analyst' => false
    }, {
      'id' => user_1.id,
      'account_id' => user_1.account.id,
      'full_name' => 'Chris Mass',
      'name' => 'Chris Mass',
      'username' => 'student',
      'is_admin' => false,
      'is_content_analyst' => false
    } ]

    results = described_class[search: '%', per_page: 2, page: 2]
    expect(results.total_items).to eq 3
    expect(results.items).to eq [ {
      'id' => admin.id,
      'account_id' => admin.account.id,
      'full_name' => 'Administrator User',
      'name' => 'Administrator User',
      'username' => 'admin',
      'is_admin' => true,
      'is_content_analyst' => false
    } ]
  end

  it 'returns profiles for their entity users' do
    profiles = described_class[search: [admin, user_1]]
    expect(profiles.total_items).to eq(2)
    expect(profiles.items).to eq [ {
      'id' => user_1.id,
      'account_id' => user_1.account.id,
      'full_name' => 'Chris Mass',
      'name' => 'Chris Mass',
      'username' => 'student',
      'is_admin' => false,
      'is_content_analyst' => false
    }, {
      'id' => admin.id,
      'account_id' => admin.account.id,
      'full_name' => 'Administrator User',
      'name' => 'Administrator User',
      'username' => 'admin',
      'is_admin' => true,
      'is_content_analyst' => false
    } ]
  end

  it 'requires that an array search is filled with User::User' do
    expect {
      described_class[search: [admin, FactoryGirl.create(:user_profile)]]
    }.to raise_error(TypeError,
                     "Tested argument was of class 'User::Models::Profile' instead of the expected 'User::User'.")
  end
end
