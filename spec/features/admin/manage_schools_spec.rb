require 'rails_helper'

RSpec.feature 'Administration' do
  before do
    admin = FactoryGirl.create(:user, :administrator)
    stub_current_user(admin)

    visit admin_schools_path
    click_link 'Add school'

    fill_in 'Name', with: 'John F Kennedy High'
    click_button 'Save'
  end

  scenario 'create a blank school' do
    expect(current_path).to eq(admin_schools_path)
    expect(page).to have_css('.flash_notice', text: 'The school has been created.')
    expect(page).to have_css('tr td', text: 'John F Kennedy High')
  end

  scenario 'edit a school' do
    click_link 'edit'

    fill_in 'Name', with: 'Edited Name'
    click_button 'Save'

    expect(current_path).to eq(admin_schools_path)
    expect(page).to have_css('.flash_notice', text: 'The school has been updated.')
    expect(page).to have_css('tr td', text: 'Edited Name')
  end

  scenario 'add a district' do
    FactoryGirl.create(:school_district_district, name: 'Good district')

    click_link 'edit'

    select 'Good district', from: 'District'
    click_button 'Save'

    expect(current_path).to eq(admin_schools_path)
    expect(page).to have_css('.flash_notice', text: 'The school has been updated.')
    expect(page).to have_css('tr td', text: 'Good district')
  end

  scenario 'destroy a school' do
    click_link 'delete'

    expect(current_path).to eq(admin_schools_path)
    expect(page).to have_css('.flash_notice', text: 'The school has been deleted.')
    expect(page).not_to have_content('John F Kennedy High')
  end

  scenario 'attempt destroying a school with courses assigned' do
    school = SchoolDistrict::Models::School.last
    course = FactoryGirl.create :course_profile_course, name: 'Physics', school: school

    click_link 'delete'

    expect(current_path).to eq(admin_schools_path)
    expect(page).to have_css('.flash_error', text: "Cannot delete a school that has courses.")
    expect(page).to have_content('John F Kennedy High')
  end
end
