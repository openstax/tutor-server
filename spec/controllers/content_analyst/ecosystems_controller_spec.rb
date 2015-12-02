require 'rails_helper'
require 'vcr_helper'

RSpec.describe ContentAnalyst::EcosystemsController, type: :controller do
  let!(:content_analyst) { FactoryGirl.create(:user, :content_analyst) }
  let!(:book_1) { FactoryGirl.create :content_book, title: 'Physics', version: '1' }
  let!(:book_2) { FactoryGirl.create :content_book, title: 'AP Biology', version: '2' }

  before { controller.sign_in(content_analyst) }

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
