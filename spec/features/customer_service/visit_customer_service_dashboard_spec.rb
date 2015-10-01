require 'rails_helper'

RSpec.describe 'Customer Service' do
  scenario 'visit the customer service dashboard' do
    customer_service_profile = FactoryGirl.create(:user_profile, :customer_service)
    customer_service_strategy = User::Strategies::Direct::User.new(customer_service_profile)
    customer_service = User::User.new(strategy: customer_service_strategy)
    stub_current_user(customer_service)

    visit customer_service_root_path

    expect(page).to have_content('Tutor Customer Service Console')
    expect(page).to have_link('Courses', href: customer_service_courses_path)
  end
end
