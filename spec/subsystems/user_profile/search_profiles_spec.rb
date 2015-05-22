require 'rails_helper'

RSpec.describe UserProfile::SearchProfiles do
  let!(:admin) { FactoryGirl.create :user_profile,
                                    :administrator,
                                    username: 'admin',
                                    full_name: 'Administrator' }
  let!(:user_1) { FactoryGirl.create :user_profile,
                                     username: 'student',
                                     full_name: 'Chris Mass' }
  let!(:user_2) { FactoryGirl.create :user_profile,
                                     username: 'teacher',
                                     full_name: 'Stan Dup' }

  it 'searches username and full name' do
    results = described_class[search_term: '%ch%']
    results.order(:id)
    expect(results).to eq [user_1, user_2]
  end
end
