require 'rails_helper'

RSpec.feature 'Administration' do
  before do
    admin = FactoryGirl.create(:user, :administrator)
    stub_current_user(admin)

    visit admin_districts_path
    click_link 'Add district'

    fill_in 'Name', with: 'Houston Independent School District'
    click_button 'Save'
  end

  scenario 'create a blank district' do
    expect(current_path).to eq(admin_districts_path)
    expect(page).to have_css('.flash_notice', text: 'The district has been created.')
    expect(page).to have_css('tr td', text: 'Houston Independent School District')
  end

  scenario 'edit a district' do
    click_link 'edit'

    fill_in 'Name', with: 'Edited Name'
    click_button 'Save'

    expect(current_path).to eq(admin_districts_path)
    expect(page).to have_css('.flash_notice', text: 'The district has been updated.')
    expect(page).to have_css('tr td', text: 'Edited Name')
  end

  scenario 'destroy a district' do
    click_link 'delete'

    expect(current_path).to eq(admin_districts_path)
    expect(page).to have_css('.flash_notice', text: 'The district has been deleted.')
    expect(page).not_to have_content('Houston Independent School District')
  end

  scenario 'attempt destroying a district with schools assigned' do
    district = SchoolDistrict::Models::District.last
    school = SchoolDistrict::CreateSchool[name: 'Cool School', district: district]

    click_link 'delete'

    expect(current_path).to eq(admin_districts_path)
    expect(page).to have_css('.flash_error', text: "Cannot delete a district that has schools.")
    expect(page).to have_content('Houston Independent School District')
  end
end
