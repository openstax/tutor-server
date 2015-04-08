require 'rails_helper'

RSpec.describe 'Administration' do
  scenario 'edit a course' do
    admin = FactoryGirl.create(:user_profile, :administrator)
    stub_current_user(admin)
    CreateCourse.call(name: 'Change me')

    visit admin_courses_path
    click_link 'edit'

    fill_in 'Name', with: 'Changed'
    click_button 'Save'

    expect(current_path).to eq(admin_courses_path)
    expect(page).to have_css('.flash_notice', text: 'The course has been updated.')
    expect(page).to have_css('tr td', text: 'Changed')
  end
end
