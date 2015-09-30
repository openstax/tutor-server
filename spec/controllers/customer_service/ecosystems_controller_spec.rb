require 'rails_helper'
require 'vcr_helper'

RSpec.describe CustomerService::EcosystemsController, type: :controller do
  let!(:customer_service) {
    profile = FactoryGirl.create(:user_profile, :customer_service)
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  }

  let!(:book_1) { FactoryGirl.create :content_book, title: 'Physics', version: '1' }
  let!(:book_2) { FactoryGirl.create :content_book, title: 'AP Biology', version: '2' }

  before { controller.sign_in(customer_service) }

  describe 'GET #index' do
    it 'lists ecosystems' do
      get :index

      expected_ecosystems = [book_2.ecosystem, book_1.ecosystem].collect do |content_ecosystem|
        strategy = ::Content::Strategies::Direct::Ecosystem.new(content_ecosystem)
        ::Content::Ecosystem.new(strategy: strategy)
      end
      expect(assigns[:ecosystems]).to eq expected_ecosystems
    end
  end
end
