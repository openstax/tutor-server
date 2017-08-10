require 'rails_helper'

RSpec.describe 'Content Analyst' do
  let!(:book) { FactoryGirl.create(:content_book, title: 'Test book') }
  let(:content_analyst) { FactoryGirl.create(:user, :content_analyst) }

  before do
    # Log in as customer service
    stub_current_user(content_analyst)

    # Go to the customer service console
    visit content_analyst_root_path

    # Click on the "Ecosystems" tab
    click_link 'Ecosystems'
  end

  scenario 'views the ecosystems' do
    expect(page).to have_css('td', text: 'Test book')
    expect(page).to_not have_link('Import a new Ecosystem')
    expect(page).to_not have_link('Delete')
  end
end
