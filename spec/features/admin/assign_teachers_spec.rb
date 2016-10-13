require 'rails_helper'
require 'feature_js_helper'

RSpec.feature 'Administration', js: true do
  before do
    # Log in as admin
    admin = FactoryGirl.create(:user, :administrator)
    stub_current_user(admin)

    # Create a user to add as a teacher
    FactoryGirl.create(
      :user_profile, username: 'imateacher', first_name: 'Ima',
      last_name: 'Teacher', full_name: 'Ima Teacher'
    )

    # Create a course
    visit admin_courses_path
    click_link 'Add Course'

    fill_in 'Name', with: 'A Course'

    click_button 'Save'
    # Edit the course
    click_link 'Edit'

    # Click on the "Teachers" tab
    click_link 'Teachers'
  end

  scenario 'adds a teacher to a course' do
    # Check that the teacher has not been added yet
    expect(page).not_to have_text('imateacher')

    # Search for the user and add the user to the course
    autocomplete '#course_teacher', with: 'imatea'
    expect(page).to have_css('.flash_notice', text: 'Teachers updated.')

    # Check that the teacher is now in the list of teachers
    expect(page).to have_text('imateacher')
  end

  scenario 'removes a teacher from a course' do
    # Search for the user and add the user to the course
    autocomplete '#course_teacher', with: 'imatea'
    expect(page).to have_css('.flash_notice', text: 'Teachers updated.')

    # Remove the teacher
    click_link 'Remove from course'
    expect(page).to have_css('.flash_notice', text: 'Teacher "Ima Teacher" removed from course.')

    # Check that the teacher is now not in the list of teachers
    expect(page).not_to have_text('imateacher')
  end
end
