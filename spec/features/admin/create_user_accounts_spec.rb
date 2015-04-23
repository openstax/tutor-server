require 'rails_helper'
require 'vcr_helper'

RSpec.feature 'Administration', vcr: VCR_OPTS do
  scenario 'create a user with a username and password' do
    admin = FactoryGirl.create(:user_profile, :administrator)
    stub_current_user(admin)

    visit admin_root_path
    click_link 'Users'
    click_link 'Create user'

    fill_in 'Username', with: 'superwoman'
    fill_in 'Password', with: 'goldenlasso25'
    click_button 'Save'

    expect(current_path).to eq(admin_users_path)
    expect(page).to have_css('.flash_notice', text: 'The user has been added.')
    expect(page).to have_css('tr td', text: 'superwoman')
  end
end
