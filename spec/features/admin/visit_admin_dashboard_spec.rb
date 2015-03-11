require 'rails_helper'

RSpec.describe 'Admnistration' do
  scenario 'visit the admin dashboard' do
    admin = FactoryGirl.create(:user, :administrator)
    stub_current_user(admin)

    visit admin_root_path

    expect(page).to have_content('Tutor Administration')
    expect(page).to have_link('Courses', href: admin_courses_path)
  end
end
