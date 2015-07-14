require 'rails_helper'

RSpec.describe 'Administration' do
  before do
    FactoryGirl.create(:district, name: 'Good district')

    admin = FactoryGirl.create(:user_profile, :administrator)
    stub_current_user(admin)

    visit admin_schools_path
    click_link 'Add school'

    fill_in 'Name', with: 'John F Kennedy High'
    select 'Good district', from: 'District'
    click_button 'Save'
  end

  scenario 'create a blank school' do
    expect(current_path).to eq(admin_schools_path)
    expect(page).to have_css('.flash_notice', text: 'The school has been created.')
    expect(page).to have_css('tr td', text: 'John F Kennedy High')
    expect(page).to have_css('tr td', text: 'Good district')
  end

  scenario 'edit a school' do
    click_link 'edit'

    fill_in 'Name', with: 'Edited Name'
    click_button 'Save'

    expect(current_path).to eq(admin_schools_path)
    expect(page).to have_css('.flash_notice', text: 'The school has been updated.')
    expect(page).to have_css('tr td', text: 'Edited Name')
  end

  scenario 'destroy a school' do
    click_link 'delete'

    expect(current_path).to eq(admin_schools_path)
    expect(page).to have_css('.flash_notice', text: 'The school has been deleted.')
    expect(page).not_to have_content('John F Kennedy High')
  end
end
