require 'rails_helper'

RSpec.feature 'Administrator' do
  scenario 'signs in as another user' do
    profile = FactoryGirl.create(:user_profile, username: 'a_user')

    admin_profile = FactoryGirl.create(:user_profile, :administrator)
    admin_strategy = User::Strategies::Direct::User.new(admin_profile)
    admin = User::User.new(strategy: admin_strategy)

    # Not logged in
    visit dashboard_path
    expect(current_path).not_to eq(dashboard_path)

    # Pretend we are an admin
    stub_current_user(admin)

    visit admin_root_path
    click_link 'Users'
    fill_in 'query', with: 'a_user'
    click_button 'Search'
    click_link 'Sign in as', match: :first

    expect(current_path).to eq(dashboard_path)

    # Remove the admin user stub so we can see the changes
    unstub_current_user

    # Still logged in
    visit dashboard_path
    expect(current_path).to eq(dashboard_path)

    # a_user is not an admin so should not be able to see the admin console
    expect { visit admin_root_path }.to raise_error(SecurityTransgression)
  end
end
