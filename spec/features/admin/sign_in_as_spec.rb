require 'rails_helper'

RSpec.feature 'Administrator' do
  scenario 'signs in as another user' do
    FactoryBot.create(:user_profile, username: 'a_user')
    page.driver.header('User-Agent', 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_4; en-US) AppleWebKit/533.4 (KHTML, like Gecko) Chrome/5.0.375.99 Safari/533.4')

    admin = FactoryBot.create(:user_profile, :administrator)

    # Not logged in
    visit courses_path
    expect(current_path).not_to eq(courses_path)

    # Pretend we are an admin
    stub_current_user(admin)

    visit admin_root_path
    click_link 'Users', match: :first
    fill_in 'query', with: 'a_user'
    click_button 'Search'
    click_link 'Sign in as', match: :first

    expect(current_path).to eq(courses_path)

    # Remove the admin user stub so we can see the changes
    unstub_current_user

    # Still logged in
    visit courses_path
    expect(current_path).to eq(courses_path)

    # a_user is not an admin so should not be able to see the admin console
    expect { visit admin_root_path }.to raise_error(SecurityTransgression)
  end
end
