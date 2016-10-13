require 'rails_helper'

RSpec.feature 'Administration' do
  before do
    admin = FactoryGirl.create(:user, :administrator)
    stub_current_user(admin)
  end

  scenario 'create a blank course' do
    visit admin_courses_path
    click_link 'Add Course'

    fill_in 'Name', with: 'Hello hi ciao Hey World'
    click_button 'Save'

    expect(current_path).to eq(admin_courses_path)
    expect(page).to have_css('.flash_notice', text: 'The course has been created.')
    expect(page).to have_text('Hello hi ciao Hey World')
  end

  scenario 'create a blank course with a catalog_offering' do
    catalog_offering = FactoryGirl.create :catalog_offering

    visit admin_courses_path
    click_link 'Add Course'

    fill_in 'Name', with: 'Hello hi ciao Hey World'
    select catalog_offering.salesforce_book_name, from: 'Catalog Offering'
    click_button 'Save'

    expect(current_path).to eq(admin_courses_path)
    expect(page).to have_css('.flash_notice', text: 'The course has been created.')
    expect(page).to have_text('Hello hi ciao Hey World')
    course = Entity::Course.order(:created_at).last
    expect(course.offering).to eq catalog_offering
    expect(course.ecosystems.first).to eq catalog_offering.ecosystem
  end
end
