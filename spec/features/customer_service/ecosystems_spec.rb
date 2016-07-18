require 'rails_helper'

RSpec.describe 'Customer Service' do
  let!(:book) { FactoryGirl.create(:content_book, title: 'Test book') }
  let(:customer_service) { FactoryGirl.create(:user, :customer_service) }

  before do
    # Log in as customer service
    stub_current_user(customer_service)

    # Go to the customer service console
    visit customer_service_root_path

    # Click on the "Ecosystems" tab
    click_link 'Ecosystems'
  end

  scenario 'views the ecosystems' do
    expect(page).to have_css('td', text: 'Test book')
    expect(page).to_not have_link('Import a new Ecosystem')
    expect(page).to_not have_link('Delete')
  end
end
