require 'rails_helper'
require 'vcr_helper'

RSpec.feature 'Admin editing a course' do
  background do
    admin = FactoryGirl.create(:user, :administrator)
    stub_current_user(admin)

    @catalog_offering = FactoryGirl.create :catalog_offering

    visit admin_courses_path

    click_on 'Add Course'
    fill_in 'Name', with: 'Physics I'
    select @catalog_offering.salesforce_book_name, from: 'Catalog Offering'
    click_on 'Save'

    @course = CourseProfile::Models::Course.order(:id).last
    FactoryGirl.create :course_membership_period, course: @course
  end

  scenario 'Editing the name of a course' do
    visit admin_courses_path
    click_link 'Edit'

    expect(page).to have_content('Edit Course')
    fill_in 'Name', with: 'Changed777888'
    click_button 'Save'

    expect(current_path).to eq(admin_courses_path)
    expect(page).to have_css('.flash_notice', text: 'The course has been updated.')
    expect(page).to have_text('Changed777888')
  end


  scenario 'Editing the course dates' do
    visit admin_courses_path
    click_link 'Edit'

    expect(page).to have_content('Edit Course')
    fill_in 'Starts at', with: '2016-01-01'
    fill_in 'Ends at', with: '2016-02-01'
    # capybara fails (only on Travis) with the Ambiguous match, found 2 elements matching button "Save"
    click_button 'Save', match: :first

    expect(current_path).to eq(admin_courses_path)
    expect(page).to have_css('.flash_notice', text: 'The course has been updated.')
    expect(page).to have_text('Term: Jan 01, 2016 - Feb 01, 2016')
  end


  scenario 'Changing "Is College"' do
    visit admin_courses_path
    click_link 'Edit'

    expect(page).to have_content('Edit Course')
    check 'course_is_college'
    click_button 'Save'

    expect(current_path).to eq(admin_courses_path)
    expect(page).to have_css('.flash_notice', text: 'The course has been updated.')
    expect(CourseProfile::Models::Course.first.is_college).to be_truthy
  end

  scenario 'Assigning a school' do
    FactoryGirl.create(:school_district_school, name: 'High high hi school')
    visit admin_courses_path
    click_link 'Edit'

    select 'High high hi school', from: 'School'
    click_button 'Save'

    expect(current_path).to eq(admin_courses_path)
    expect(page).to have_text('High high hi school')
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
    select @catalog_offering.salesforce_book_name, from: 'Catalog Offering'
    click_on 'Save'

    course_2 = CourseProfile::Models::Course.order(:id).last

    find(:id, :ecosystem_id).find("option[value='#{physics_new.id}']").select_option
    click_on 'Set Ecosystem'
    expect(page).to have_content('Course ecosystem update background jobs queued')
    expect(@course.ecosystems.first.books.first.version).to eq('5.1')
    expect(course_2.ecosystems.first.books.first.version).to eq('5.1')
  end
end
