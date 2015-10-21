require 'rails_helper'
require 'vcr_helper'

RSpec.describe Admin::EcosystemsController, speed: :slow, vcr: VCR_OPTS do
  let!(:admin) { FactoryGirl.create(:user, :administrator) }

  let!(:book_1) { FactoryGirl.create :content_book, title: 'Physics', version: '1' }
  let!(:book_2) { FactoryGirl.create :content_book, title: 'AP Biology', version: '2' }

  before { controller.sign_in(admin) }

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

  describe 'POST #import' do
    let!(:archive_url) { 'https://archive-staging-tutor.cnx.org/contents/' }
    let!(:cnx_id) { '93e2b09d-261c-4007-a987-0b3062fe154b@4.4' }

    it 'imports books and exercises as ecosystems' do
      expect {
        post :import, archive_url: archive_url, cnx_id: cnx_id
      }.to change { Content::Models::Book.count }.by(1)
      expect(flash[:notice]).to include 'Ecosystem import job queued.'
    end

    it 'imports a book even if the book already exists' do
      FactoryGirl.create(:content_book,
                         title: 'Physics',
                         url: "#{archive_url}#{cnx_id}",
                         version: '4.4')

      expect {
        post :import, archive_url: archive_url, cnx_id: cnx_id
      }.to change { Content::Models::Book.count }.by(1)
      expect(flash[:notice]).to include 'Ecosystem import job queued.'
    end

    it 'imports a book with a different version' do
      FactoryGirl.create(:content_book,
                         title: 'Physics',
                         url: "#{archive_url}#{cnx_id}",
                         version: '4.4')

      expect {
        post :import, archive_url: archive_url, cnx_id: cnx_id.sub('@4.4', '@4.3')
      }.to change { Content::Models::Book.count }.by(1)
      expect(flash[:notice]).to include 'Ecosystem import job queued.'
    end

    it 'creates a proper TagGenerator if the cc_tag param is given' do
      tag_generator = ConceptCoach::TagGenerator.new('test')
      expect(ConceptCoach::TagGenerator).to receive(:new).with('test').and_return(tag_generator)
      expect(FetchAndImportBookAndCreateEcosystem).to receive(:perform_later).with(
        book_cnx_id: cnx_id,
        tag_generator: Marshal.dump(tag_generator)
      ).and_call_original

      post :import, archive_url: archive_url, cnx_id: cnx_id, cc_tag: 'test'
    end
  end
end
