require 'rails_helper'

RSpec.describe 'Admnistration' do
  scenario 'visit the admin dashboard' do
    admin_profile = FactoryGirl.create(:user_profile, :administrator)
    admin_strategy = User::Strategies::Direct::User.new(admin_profile)
    admin = User::User.new(strategy: admin_strategy)
    stub_current_user(admin)

    visit admin_root_path

    expect(page).to have_content('Tutor Admin Console')
    expect(page).to have_link('Courses', href: admin_courses_path)
  end
end
