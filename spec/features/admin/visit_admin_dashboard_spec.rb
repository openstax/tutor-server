require 'rails_helper'

RSpec.feature 'Admnistration' do
  scenario 'visit the admin dashboard' do
    admin = FactoryGirl.create(:user, :administrator)
    stub_current_user(admin)

    visit admin_root_path

    expect(page).to have_content('Tutor Admin Console')
    expect(page).to have_link('Courses', href: admin_courses_path)
  end

  context 'pages are reachable via the menu' do
    before(:each) do
      admin = FactoryGirl.create(:user, :administrator)
      stub_current_user(admin)
      visit admin_root_path
    end

    scenario 'System Setting/Settings' do
      click_link 'System Setting'
      click_link 'Settings'
    end
  end
end
