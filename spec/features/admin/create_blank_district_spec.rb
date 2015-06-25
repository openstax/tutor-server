require 'rails_helper'

RSpec.describe 'Administration' do
  scenario 'create a blank course' do
    admin = FactoryGirl.create(:user_profile, :administrator)
    stub_current_user(admin)

    visit admin_districts_path
    click_link 'Add district'

    fill_in 'Name', with: 'Houston Independent School District'
    click_button 'Save'

    expect(current_path).to eq(admin_districts_path)
    expect(page).to have_css('.flash_notice', text: 'The district has been created.')
    expect(page).to have_css('tr td', text: 'Houston Independent School District')
  end

  scenario 'edit a course' do
    admin = FactoryGirl.create(:user_profile, :administrator)
    stub_current_user(admin)

    visit admin_districts_path
    click_link 'Add district'

    fill_in 'Name', with: 'Houston Independent School District'
    click_button 'Save'

    click_link 'edit'

    fill_in 'Name', with: 'Edited Name'
    click_button 'Save'

    expect(current_path).to eq(admin_districts_path)
    expect(page).to have_css('.flash_notice', text: 'The district has been updated.')
    expect(page).to have_css('tr td', text: 'Edited Name')
  end
end
