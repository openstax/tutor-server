require 'rails_helper'

RSpec.describe User::SearchUsers, type: :routine do
  let!(:admin) { FactoryBot.create :user, :administrator,
                                           username: 'admin',
                                           first_name: 'Administrator',
                                           last_name: 'User' }
  let!(:user_1) { FactoryBot.create :user, username: 'student',
                                            first_name: 'Chris',
                                            last_name: 'Mass' }
  let!(:user_2) { FactoryBot.create :user, username: 'teacher',
                                            first_name: 'Stan',
                                            last_name: 'Dup' }

  it 'searches username and name' do
    results = described_class[search: '%ch%']
    expect(results.total_count).to eq 2
    expect(Set.new results.items).to eq Set.new [user_1, user_2]
  end

  it 'paginates results' do
    results = described_class[search: '%', per_page: 2, page: 1]
    expect(results.total_count).to eq 3
    expect(Set.new results.items).to eq Set.new [user_1, user_2]

    results = described_class[search: '%', per_page: 2, page: 2]
    expect(results.total_count).to eq 3
    expect(results.items).to eq [admin]
  end
end
