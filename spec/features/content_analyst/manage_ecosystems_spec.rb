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

  scenario 'imports a tutor book' do
    click_link 'Import a new Ecosystem'

    attach_file('Ecosystem Manifest (.yml)',
                File.absolute_path('spec/fixtures/content/sample_tutor_manifest.yml'))
    fill_in 'Comments', with: 'This version includes typo fixes to quantum equations'
    click_button 'Import'

    expect(page).to have_css('.flash_notice', text: 'Ecosystem import job queued.')
    expect(page).to have_css('td', text: 'Physics')
    expect(page).to have_css('td', text: '4.4')
    expect(page).to have_field('ecosystem[comments]',
                               with: 'This version includes typo fixes to quantum equations')
    expect(page).to have_css('[data-content="93e2b09d-261c-4007-a987-0b3062fe154b"]')
  end

  scenario 'imports a cc book' do
    click_link 'Import a new Ecosystem'

    attach_file('Ecosystem Manifest (.yml)',
                File.absolute_path('spec/fixtures/content/sample_cc_manifest.yml'))
    fill_in 'Comments', with: 'This version includes typo fixes to genetic algorithms'
    click_button 'Import'

    expect(page).to have_css('.flash_notice', text: 'Ecosystem import job queued.')
    expect(page).to have_css('td', text: 'Mini CC Biology Tes Coll')
    expect(page).to have_css('td', text: '2.1')
    expect(page).to have_field('ecosystem[comments]',
                               with: 'This version includes typo fixes to genetic algorithms')
    expect(page).to have_css('[data-content="f10533ca-f803-490d-b935-88899941197f"]')
  end

  scenario 'edits ecosystem comments' do
    FactoryGirl.create(:content_book, title: 'Test Book')

    click_link 'Ecosystems'
    expect(page).to have_css('td', text: 'Test Book')

    fill_in 'ecosystem[comments]', with: 'Add some comments'
    click_on 'Save'

    expect(page).to have_field('ecosystem[comments]', with: 'Add some comments')
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
