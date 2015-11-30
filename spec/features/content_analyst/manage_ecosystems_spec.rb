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
    fill_in 'Comments', with: 'This version includes typo fixes to quantum equations'
    click_button 'Import'

    expect(page).to have_css('.flash_notice', text: 'Ecosystem import job queued.')
    expect(page).to have_css('td', text: 'Physics')
    expect(page).to have_css('td', text: '4.4')
    expect(page).to have_css('td', text: 'This version includes typo fixes to quantum equations')
    expect(page).to have_css('[data-content="93e2b09d-261c-4007-a987-0b3062fe154b"]')
  end

  scenario 'imports a book without explicit archive url' do
    click_link 'Import a new Ecosystem'

    fill_in 'Book CNX id', with: '93e2b09d-261c-4007-a987-0b3062fe154b@4.4'
    fill_in 'Comments', with: 'This version includes typo fixes to quantum equations'
    click_button 'Import'

    expect(page).to have_css('.flash_notice', text: 'Ecosystem import job queued.')
    expect(page).to have_css('td', text: 'Physics')
    expect(page).to have_css('td', text: '4.4')
    expect(page).to have_css('td', text: 'This version includes typo fixes to quantum equations')
    expect(page).to have_css('[data-content="93e2b09d-261c-4007-a987-0b3062fe154b"]')
  end

  scenario 'deletes an ecosystem' do
    FactoryGirl.create(:content_book, title: 'Test Book')

    click_link 'Ecosystems'
    expect(page).to have_css('td', text: 'Test Book')

    click_link 'Delete'
    expect(page).to have_css('.flash_notice', text: 'Ecosystem deleted.')
    expect(page).to_not have_css('td', text: 'Test Book')
  end
end
