require 'rails_helper'

RSpec.describe 'Customer Service' do
  scenario 'visit the customer service dashboard' do
    stub_current_user(FactoryBot.create(:user_profile, :customer_service))

    visit customer_service_root_path

    expect(page).to have_content('Tutor Customer Service Console')
    expect(page).to have_link('Courses', href: customer_service_courses_path)
  end
end
