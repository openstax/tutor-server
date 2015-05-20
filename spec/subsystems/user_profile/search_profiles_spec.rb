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
    results.sort_by! { |r| r.id }
    expect(results).to eq [ {
      'id' => user_1.id,
      'account_id' => user_1.account.id,
      'entity_user_id' => user_1.entity_user.id,
      'full_name' => 'Chris Mass',
      'username' => 'student'
    }, {
      'id' => user_2.id,
      'account_id' => user_2.account.id,
      'entity_user_id' => user_2.entity_user.id,
      'full_name' => 'Stan Dup',
      'username' => 'teacher'
    } ]
  end
end
