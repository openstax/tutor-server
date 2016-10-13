require 'rails_helper'

RSpec.feature 'Administration' do
  scenario 'create a blank course' do
    admin = FactoryGirl.create(:user, :administrator)
    stub_current_user(admin)

    catalog_offering = FactoryGirl.create :catalog_offering

    visit admin_courses_path
    click_link 'Add Course'

    fill_in 'Name', with: 'Hello hi ciao Hey World'
    select catalog_offering.salesforce_book_name, from: 'Catalog Offering'
    click_button 'Save'

    expect(current_path).to eq(admin_courses_path)
    expect(page).to have_css('.flash_notice', text: 'The course has been created.')
    expect(page).to have_text('Hello hi ciao Hey World')
  end
end
