require 'rails_helper'

RSpec.feature 'Administration' do
  scenario 'create a blank course' do
    stub_oauth_sign_in

    visit admin_courses_path
    click_button 'Add Course'

    expect(current_path).to eq(admin_courses_path)
    expect(page).to have_css('.flash_notice',
                             text: 'The course has been created.')
    expect(page).to have_css("##{dom_id(Entity::Course.last)}",
                             text: 'less than a minute ago')
  end
end
