require 'rails_helper'

RSpec.feature 'Administration' do
  scenario 'create a blank course' do
    admin_profile = FactoryGirl.create(:user_profile, :administrator)
    admin_strategy = User::Strategies::Direct::User.new(admin_profile)
    admin = User::User.new(strategy: admin_strategy)
    stub_current_user(admin)

    visit admin_courses_path
    click_link 'Add Course'

    fill_in 'Name', with: 'Hello World'
    click_button 'Save'

    expect(current_path).to eq(admin_courses_path)
    expect(page).to have_css('.flash_notice', text: 'The course has been created.')
    expect(page).to have_css("tr td", text: 'Hello World')
  end
end
