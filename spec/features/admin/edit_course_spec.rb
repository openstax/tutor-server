require 'rails_helper'

RSpec.feature 'Admin editing a course' do
  background do
    admin = FactoryGirl.create(:user, :administrator)
    stub_current_user(admin)

    @course = CreateCourse[name: 'Physics I']
    CreatePeriod[course: @course, name: '1st']
  end

  scenario 'Editing the name of a course' do
    visit admin_courses_path
    click_link 'Edit'

    expect(page).to have_content('Edit Course')
    fill_in 'Name', with: 'Changed'
    click_button 'Save'

    expect(current_path).to eq(admin_courses_path)
    expect(page).to have_css('.flash_notice', text: 'The course has been updated.')
    expect(page).to have_css('tr td', text: 'Changed')
  end

  scenario 'Assigning a school' do
    FactoryGirl.create(:school, name: 'School name')
    visit admin_courses_path
    click_link 'Edit'

    select 'School name', from: 'School'
    click_button 'Save'

    expect(current_path).to eq(admin_courses_path)
    expect(page).to have_css('tr td', text: 'School name')
  end

  scenario 'Adding a period' do
    visit admin_courses_path
    click_link 'Edit'

    click_link 'Add period'
    expect(page).to have_content('New Period for Physics I')

    fill_in 'Name', with: '2nd'
    click_button 'Save'

    expect(current_path).to eq(edit_admin_course_path(@course))
    expect(page).to have_content('2nd Edit')
  end

  scenario 'Editing a period' do
    visit admin_courses_path
    click_link 'Edit'

    click_link 'Edit'
    expect(page).to have_content('Edit Period')

    fill_in 'Name', with: 'first'
    click_button 'Save'

    expect(current_path).to eq(edit_admin_course_path(@course))
    expect(page).to have_content('first Edit')
  end
end
