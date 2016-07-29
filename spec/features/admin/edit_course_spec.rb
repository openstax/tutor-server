require 'rails_helper'
require 'vcr_helper'

RSpec.feature 'Admin editing a course' do
  background do
    admin = FactoryGirl.create(:user, :administrator)
    stub_current_user(admin)

    visit admin_courses_path

    click_on 'Add Course'
    fill_in 'Name', with: 'Physics I'
    click_on 'Save'

    @course = Entity::Course.order(:id).last
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

  scenario 'Changing "Is College"' do
    visit admin_courses_path
    click_link 'Edit'

    expect(page).to have_content('Edit Course')
    check 'course_is_college'
    click_button 'Save'

    expect(current_path).to eq(admin_courses_path)
    expect(page).to have_css('.flash_notice', text: 'The course has been updated.')
    expect(Entity::Course.first.is_college).to be_truthy
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
    expect(page).to have_content('Enrollment code')

    fill_in 'Name', with: '2nd'
    click_button 'Save'

    expect(current_path).to eq(edit_admin_course_path(@course))
    period = CourseMembership::Models::Period.find_by_name('2nd')
    expect(page).to have_content("2nd #{period.enrollment_code} Edit")
  end

  scenario 'Editing a period' do
    visit admin_courses_path
    click_link 'Edit'

    click_link 'Edit'
    expect(page).to have_content('Edit Period')

    fill_in 'Name', with: 'first'
    fill_in 'Enrollment code', with: 'happy restrictions'
    click_button 'Save'

    expect(current_path).to eq(edit_admin_course_path(@course))
    expect(page).to have_content('first happy restrictions Edit')
  end

  scenario 'bulk updating course ecosystem', speed: :slow, vcr: VCR_OPTS do
    physics_old_cnx_id = '93e2b09d-261c-4007-a987-0b3062fe154b@4.4'
    physics_old = FetchAndImportBookAndCreateEcosystem[
      book_cnx_id: physics_old_cnx_id]
    physics_new_cnx_id = '93e2b09d-261c-4007-a987-0b3062fe154b@5.1'
    physics_new = FetchAndImportBookAndCreateEcosystem[
      book_cnx_id: physics_new_cnx_id]

    visit admin_courses_path
    find(:id, :ecosystem_id).find("option[value='#{physics_old.id}']").select_option
    click_on 'Set Ecosystem'

    expect(page).to have_content('Course ecosystem update background jobs queued')
    expect(@course.ecosystems.first.books.first.version).to eq('4.4')

    click_on 'Add Course'
    fill_in 'Name', with: 'Physics II'
    click_on 'Save'

    course_2 = Entity::Course.order(:id).last

    find(:id, :ecosystem_id).find("option[value='#{physics_new.id}']").select_option
    click_on 'Set Ecosystem'
    expect(page).to have_content('Course ecosystem update background jobs queued')
    expect(@course.ecosystems.first.books.first.version).to eq('5.1')
    expect(course_2.ecosystems.first.books.first.version).to eq('5.1')
  end
end
