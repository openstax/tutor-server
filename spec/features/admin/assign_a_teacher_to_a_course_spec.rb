require 'rails_helper'

RSpec.feature 'Administration' do
  before do
    Domain::CreateCourse.call

    FactoryGirl.create(:user, full_name: 'Teacher')
    FactoryGirl.create(:user, full_name: 'Other Teacher')
    FactoryGirl.create(:user, full_name: 'Not a Teacher')

    admin = FactoryGirl.create(:user, :administrator)
    stub_current_user(admin)
  end

  scenario 'assign a teacher to a course' do
    visit admin_courses_path
    click_link 'edit'

    select 'Teacher', from: 'Assign teachers'
    select 'Other Teacher', from: 'Assign teachers'
    click_button 'Save'

    expect(current_path).to eq(admin_courses_path)
    expect(page).to have_css('.flash_notice', text: 'The course has been updated.')
    expect(page).to have_css('tr td', text: 'Other Teacher and Teacher')
  end
end
