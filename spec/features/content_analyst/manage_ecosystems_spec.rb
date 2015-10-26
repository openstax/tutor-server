require 'rails_helper'
require 'vcr_helper'

RSpec.describe 'Content Analyst', speed: :slow, vcr: VCR_OPTS do
  before do
    # Log in as content analyst
    content_analyst = FactoryGirl.create(:user, :content_analyst)
    stub_current_user(content_analyst)

    # Go to the content analyst console
    visit content_analyst_root_path

    # Click on the "Ecosystems" tab
    click_link 'Ecosystems'
  end

  scenario 'imports a book' do
    click_link 'Import a new Ecosystem'

    fill_in 'Archive url', with: 'https://archive-staging-tutor.cnx.org/contents/'
    fill_in 'Book CNX id', with: '93e2b09d-261c-4007-a987-0b3062fe154b@4.4'
    click_button 'Import'

    expect(page).to have_css('.flash_notice', text: 'Ecosystem import job queued.')
    expect(page).to have_css('td', text: 'Physics')
    expect(page).to have_css('td', text: '93e2b09d-261c-4007-a987-0b3062fe154b')
    expect(page).to have_css('td', text: '4.4')
  end
end
