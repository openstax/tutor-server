require 'rails_helper'
require 'vcr_helper'

RSpec.feature 'Administration', vcr: VCR_OPTS do
  scenario 'create a user with a username and password' do
    @previous_url = OpenStax::Accounts.configuration.openstax_accounts_url
    @previous_client_id = OpenStax::Accounts.configuration.openstax_application_id
    @previous_secret = OpenStax::Accounts.configuration.openstax_application_secret
    @previous_enable_stubbing = OpenStax::Accounts.configuration.enable_stubbing
    OpenStax::Accounts.configuration.openstax_accounts_url = 'http://accounts-dev1.openstax.org'
    OpenStax::Accounts.configuration.openstax_application_id = \
      'bafcf3ed42cbfc87fcfc63e2a444eacb8ece508f5f69208d745e12eff3825135'
    OpenStax::Accounts.configuration.openstax_application_secret = \
      'bc9d18e693334b40c67b28fb93eff30bbfc9f1aca161e33bd5b097b00b304608'
    OpenStax::Accounts.configuration.enable_stubbing = false

    admin = FactoryGirl.create(:user_profile, :administrator)
    stub_current_user(admin)

    visit admin_root_path
    click_link 'Users'
    click_link 'Create user'

    fill_in 'Username', with: 'superwoman'
    fill_in 'Password', with: 'goldenlasso25'
    fill_in 'First name', with: 'Super'
    fill_in 'Last name', with: 'Woman'
    click_button 'Save'

    expect(current_path).to eq(admin_users_path)
    expect(page).to have_css('.flash_notice', text: 'The user has been added.')
    expect(page).to have_css('tr td', text: 'superwoman')

    OpenStax::Accounts.configuration.openstax_accounts_url = @previous_url
    OpenStax::Accounts.configuration.openstax_application_id = @previous_client_id
    OpenStax::Accounts.configuration.openstax_application_secret = @previous_secret
    OpenStax::Accounts.configuration.enable_stubbing = @previous_enable_stubbing
  end
end
