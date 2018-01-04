require 'rails_helper'
require 'vcr_helper'

RSpec.feature 'Administration', vcr: VCR_OPTS do
  set_vcr_config_around(:all, ignore_localhost: false)

  before(:all) do
    @previous_url = OpenStax::Accounts.configuration.openstax_accounts_url
    @previous_client_id = OpenStax::Accounts.configuration.openstax_application_id
    @previous_secret = OpenStax::Accounts.configuration.openstax_application_secret
    @previous_enable_stubbing = OpenStax::Accounts.configuration.enable_stubbing

    OpenStax::Accounts.configuration.openstax_accounts_url = 'http://localhost:2999'
    OpenStax::Accounts.configuration.openstax_application_id = \
      '2ca11daee85d79b0e392c840a0c65ccf592782f0d30e73099687b5b27d761452'
    OpenStax::Accounts.configuration.openstax_application_secret = \
      '8d3527f95bd7c96a4abde8f0146c04a6033c11c27fff5f591142d45f0bff69fc'
    OpenStax::Accounts.configuration.enable_stubbing = false
  end

  after(:all) do
    OpenStax::Accounts.configuration.openstax_accounts_url = @previous_url
    OpenStax::Accounts.configuration.openstax_application_id = @previous_client_id
    OpenStax::Accounts.configuration.openstax_application_secret = @previous_secret
    OpenStax::Accounts.configuration.enable_stubbing = @previous_enable_stubbing
  end

  before do
    admin = FactoryBot.create(:user, :administrator)
    stub_current_user(admin)

    visit admin_root_path
    click_link 'Users'
    click_link 'Create user'
  end

  scenario 'create a user with a username and password' do
    fill_in 'Username', with: 'superwoman'
    fill_in 'Password', with: 'goldenlasso25'
    fill_in 'First name', with: 'Super'
    fill_in 'Last name', with: 'Woman'
    click_button 'Save'

    expect(current_path).to eq(admin_users_path)
    expect(page).to have_css('.flash_notice', text: 'The user has been added.')
    expect(page).to have_css('tr td', text: 'superwoman')
  end

  scenario 'create a user with an existing account' do
    user = User::CreateUser[username: 'superwoman',
                            password: 'goldenlasso25',
                            first_name: 'Super',
                            last_name: 'Woman',
                            full_name: 'Super Woman',
                            title: 'Justice Prevailer',
                            email: 'match@me.com']

    visit new_admin_user_path

    fill_in 'Username', with: user.username
    fill_in 'Password', with: 'goldenlasso25'
    fill_in 'First name', with: user.first_name
    fill_in 'Last name', with: user.last_name
    fill_in 'Full name override', with: user.full_name
    fill_in 'Email', with: 'match@me.com'
    fill_in 'Title', with: user.title
    click_button 'Save'

    expect(current_path).to eq(new_admin_user_path)
    expect(page).to(
      have_css('.flash_error', text: 'Invalid user information. has already been taken')
    )
  end
end
