require 'rails_helper'

RSpec.describe 'Admnistration' do
  scenario 'visit the admin dashboard' do
    admin = FactoryGirl.create(:user, :administrator)
    stub_current_user(admin)

    visit admin_root_path

    expect(page).to have_content('Tutor Admin Console')
    expect(page).to have_link('Courses', href: admin_courses_path)
  end

  context 'pages are reachable via the menu' do
    scenario 'System Setting/Settings' do
      admin = FactoryGirl.create(:user, :administrator)
      stub_current_user(admin)
      visit admin_root_path

      click_link 'System Setting'
      click_link 'Settings'
    end

    scenario 'Salesforce' do
      admin = FactoryGirl.create(:user, :administrator)
      stub_current_user(admin)
      stub_current_user(admin, OpenStax::Salesforce::SettingsController)
      visit admin_root_path

      click_link 'Salesforce'
      click_link 'Setup'
      expect(page).to have_content "Salesforce Setup"
    end
  end
end
