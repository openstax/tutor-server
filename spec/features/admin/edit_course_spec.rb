require 'rails_helper'
require 'vcr_helper'
require 'feature_js_helper'

RSpec.feature 'Admin editing a course', speed: :slow do
  background do
    admin = FactoryBot.create(:user, :administrator)
    stub_current_user(admin)

    @catalog_offering = FactoryBot.create :catalog_offering

    visit admin_courses_path

    click_on 'Add Course'
    fill_in 'Name', with: 'Physics I'
    select @catalog_offering.salesforce_book_name, from: 'Catalog Offering'
    click_on 'Save'
    expect(page).to have_content('The course has been created.')

    @course = CourseProfile::Models::Course.order(:created_at).last
    @course.update_attribute :does_cost, true
    FactoryBot.create :course_membership_period, course: @course
  end

  scenario 'Editing the name of a course' do
    visit admin_courses_path
    click_link 'Edit'

    expect(page).to have_content('Edit course')
    fill_in 'Name', with: 'Changed777888'
    click_button 'edit-save'

    expect(current_path).to eq(edit_admin_course_path(@course))
    expect(page).to have_css('.flash_notice', text: 'The course has been updated.')
    expect(find_field('Name').value).to eq 'Changed777888'
  end


  scenario 'Editing the course dates' do
    visit admin_courses_path
    click_link 'Edit'

    expect(page).to have_content('Edit course')
    fill_in 'Starts at', with: '2016-01-01'
    fill_in 'Ends at', with: '2016-02-01'
    # capybara fails (only on Travis) with the Ambiguous match, found 2 elements matching button "Save"
    click_button 'Save', match: :first

    expect(current_path).to eq(edit_admin_course_path(@course))
    expect(page).to have_css('.flash_notice', text: 'The course has been updated.')
    starts_at = DateTime.parse("2016-01-01")
    expect(@course.reload.starts_at).to eq starts_at
    # expect(page).to have_text('Term: Jan 01, 2016 - Feb 01, 2016')
  end


  scenario 'Changing "Is College"' do
    @course.update_attribute :is_college, nil

    visit admin_courses_path
    click_link 'Edit'

    expect(current_path).to eq(edit_admin_course_path(@course))
    expect(page).to have_content('Edit course')
    expect(page).to have_content('Is college Unknown Yes No')
    select 'Yes', from: 'course_is_college'
    click_button 'edit-save'

    expect(current_path).to eq(edit_admin_course_path(@course))
    expect(page).to have_css('.flash_notice', text: 'The course has been updated.')
    expect(@course.reload.is_college).to eq true

    expect(page).to have_content('Edit course')
    expect(page).to have_content('Is college Unknown Yes No')
    select 'No', from: 'course_is_college'
    click_button 'edit-save'

    expect(current_path).to eq(edit_admin_course_path(@course))
    expect(page).to have_css('.flash_notice', text: 'The course has been updated.')
    expect(@course.reload.is_college).to eq false

    expect(page).to have_content('Edit course')
    expect(page).to have_content('Is college Unknown Yes No')
    select 'Unknown', from: 'course_is_college'
    click_button 'edit-save'

    expect(current_path).to eq(edit_admin_course_path(@course))
    expect(page).to have_css('.flash_notice', text: 'The course has been updated.')
    expect(@course.reload.is_college).to be_nil

    expect(page).to have_content('Edit course')
    expect(page).to have_content('Is college Unknown Yes No')
  end

  scenario 'Changing "Is Test"' do
    visit admin_courses_path
    click_link 'Edit'

    expect(page).to have_content('Edit course')
    check 'course_is_test'
    click_button 'edit-save'

    expect(current_path).to eq(edit_admin_course_path(@course))
    expect(page).to have_css('.flash_notice', text: 'The course has been updated.')
    expect(CourseProfile::Models::Course.first.is_test).to be_truthy
  end

  scenario 'Changing "Does Cost"' do
    visit admin_courses_path
    click_link 'Edit'

    expect(page).to have_content('Edit course')
    uncheck 'course_does_cost'
    click_button 'edit-save'

    expect(current_path).to eq(edit_admin_course_path(@course))
    expect(page).to have_css('.flash_notice', text: 'The course has been updated.')
    expect(CourseProfile::Models::Course.first.does_cost).to eq false

    check 'course_does_cost'
    click_button 'edit-save'

    expect(current_path).to eq(edit_admin_course_path(@course))
    expect(page).to have_css('.flash_notice', text: 'The course has been updated.')
    expect(CourseProfile::Models::Course.first.does_cost).to eq true
  end

  scenario 'Changing "Is LMS Enabling Allowed"' do
    visit admin_courses_path
    click_link 'Edit'

    expect(page).to have_content('Edit course')
    check 'course_is_lms_enabling_allowed'
    click_button 'edit-save'

    expect(current_path).to eq(edit_admin_course_path(@course))
    expect(page).to have_css('.flash_notice', text: 'The course has been updated.')
    expect(@course.reload.is_lms_enabling_allowed).to eq true

    uncheck 'course_is_lms_enabling_allowed'
    click_button 'edit-save'

    expect(current_path).to eq(edit_admin_course_path(@course))
    expect(page).to have_css('.flash_notice', text: 'The course has been updated.')
    expect(@course.reload.is_lms_enabling_allowed).to eq false
  end

  scenario 'Assigning a school' do
    FactoryBot.create(:school_district_school, name: 'High high hi school')
    visit admin_courses_path
    click_link 'Edit'

    select 'High high hi school', from: 'School'
    click_button 'edit-save'

    expect(current_path).to eq(edit_admin_course_path(@course))
    expect(page).to have_text('High high hi school')
  end

  scenario 'Adding a period', js: true do
    visit admin_courses_path
    click_link 'Edit'

    click_link 'Periods'
    click_link 'Add period'
    expect(page).to have_content('New Period for Physics I')
    expect(page).to have_content('Enrollment code')

    fill_in 'Name', with: '2nd'
    click_button 'Save'

    expect(current_path).to eq(edit_admin_course_path(@course))
    period = CourseMembership::Models::Period.find_by_name('2nd')
    expect(page).to have_content("2nd #{period.enrollment_code} Edit")
  end

  scenario 'Editing a period', js: true do
    visit admin_courses_path
    click_link 'Edit'

    click_link 'Periods'
    click_link 'Add period'
    expect(page).to have_content('Enrollment code')

    fill_in 'Name', with: 'first'
    fill_in 'Enrollment code', with: 'happy restrictions'
    click_button 'Save'

    expect(current_path).to eq(edit_admin_course_path(@course))
    expect(page).to have_content('first happy restrictions Edit')
  end

  scenario 'bulk updating course ecosystem', vcr: VCR_OPTS do
    physics_old_cnx_id = '93e2b09d-261c-4007-a987-0b3062fe154b@4.4'
    physics_old = FetchAndImportBookAndCreateEcosystem[
      book_cnx_id: physics_old_cnx_id]
    physics_new_cnx_id = '93e2b09d-261c-4007-a987-0b3062fe154b@5.1'
    physics_new = FetchAndImportBookAndCreateEcosystem[
      book_cnx_id: physics_new_cnx_id]

    visit admin_courses_path
    find(:id, :ecosystem_id).find("option[value='#{physics_old.id}']").select_option
    click_on 'Set Ecosystem'

    expect(page).to have_content('Course ecosystem updates have been queued')
    expect(@course.ecosystem.books.first.version).to eq('4.4')

    click_on 'Add Course'
    fill_in 'Name', with: 'Physics II'
    select @catalog_offering.salesforce_book_name, from: 'Catalog Offering'
    click_on 'Save'

    course_2 = CourseProfile::Models::Course.order(:id).last

    find(:id, :ecosystem_id).find("option[value='#{physics_new.id}']").select_option
    click_on 'Set Ecosystem'
    expect(page).to have_content('Course ecosystem updates have been queued')
    expect(@course.ecosystem.books.first.version).to eq('5.1')
    expect(course_2.ecosystem.books.first.version).to eq('5.1')
  end

  scenario 'Check payment fields on student roster', js: true do
    user_1 = FactoryBot.create(:user, last_name: "AAAA")
    user_2 = FactoryBot.create(:user, last_name: "BBBB")

    student_1 = AddUserAsPeriodStudent[user: user_1, period: @course.periods.first].student
    student_2 = AddUserAsPeriodStudent[user: user_2, period: @course.periods.first].student

    student_1.is_paid = true
    student_1.save!

    student_2.is_comped = true
    student_2.save!

    visit admin_courses_path
    click_link 'Edit'
    click_link 'Roster'

    expect(page).to have_content(/.*Yes.*No.*No.*Yes/)

    click_link('No')
    wait_for_ajax

    expect(page).to have_content(/.*Yes.*Yes.*No.*Yes/)

    first('#students tbody tr').click_link("11:59:59")
    wait_for_ajax
    click_link('3')
    wait_for_ajax

    expect(first('#students tbody tr').text).to match(/3, \d\d\d\d 11:59/)
  end

  scenario 'refunding student payment', js: true do
    user = FactoryBot.create(:user, last_name: "AAAA")
    student = AddUserAsPeriodStudent[user: user, period: @course.periods.first].student

    OpenStax::Payments::Api.client.fake_pay(product_instance_uuid: student.uuid)
    # Payments will cause us to update payment status, so simulate that here
    UpdatePaymentStatus[uuid: student.uuid]

    visit admin_courses_path
    click_link 'Edit'
    click_link 'Roster'

    expect(page).to have_content(/.*Yes \(Refund\).*/)

    click_link('Refund')
    alert.accept

    expect(page).to have_content(/.*Yes \(Refund pending\).*/)

    # Payments will cause us to update payment status, so simulate that here
    UpdatePaymentStatus[uuid: student.uuid]

    student.reload
    expect(student.is_paid).to eq false
    expect(student.is_refund_pending).to eq false

    page.evaluate_script("window.location.reload()")

    expect(page).not_to have_content(/.*Refund.*/)
  end
end
