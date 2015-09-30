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
    expect(Set.new results.items).to eq Set.new [user_1, user_2]
  end

  it 'paginates results' do
    results = described_class[search: '%', per_page: 2, page: 1]
    expect(results.total_items).to eq 3
    expect(Set.new results.items).to eq Set.new [user_1, user_2]

    results = described_class[search: '%', per_page: 2, page: 2]
    expect(results.total_items).to eq 3
    expect(results.items).to eq [admin]
  end
end
