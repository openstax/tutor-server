require 'rails_helper'
require 'vcr_helper'

RSpec.describe CustomerService::EcosystemsController, type: :controller do
  let(:customer_service) { FactoryBot.create(:user, :customer_service) }

  let(:book_1) { FactoryBot.create :content_book, title: 'Physics', version: '1' }
  let!(:ecosystem_1) { Content::Ecosystem.find(book_1.ecosystem.id) }
  let(:book_2) { FactoryBot.create :content_book, title: 'AP Biology', version: '2' }
  let!(:ecosystem_2) { Content::Ecosystem.find(book_2.ecosystem.id) }

  before { controller.sign_in(customer_service) }

  context 'GET #index' do
    it 'lists ecosystems' do
      get :index

      expected_ecosystems = [book_2.ecosystem, book_1.ecosystem].map do |content_ecosystem|
        strategy = ::Content::Strategies::Direct::Ecosystem.new(content_ecosystem)
        ::Content::Ecosystem.new(strategy: strategy)
      end
      expect(assigns[:ecosystems]).to eq expected_ecosystems
    end
  end

  context 'GET #manifest' do
    it 'allows the ecosystem\'s manifest to be downloaded' do
      get :manifest, params: { id: ecosystem_1.id }

      expected_content_disposition = \
        "attachment; filename=\"#{FilenameSanitizer.sanitize(ecosystem_1.title)}.yml\""
      expect(response.headers['Content-Disposition']).to eq expected_content_disposition
      expect(response.body).to eq ecosystem_1.manifest.to_yaml
    end
  end
end
