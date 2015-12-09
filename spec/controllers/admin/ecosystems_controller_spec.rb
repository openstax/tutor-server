require 'rails_helper'
require 'vcr_helper'

RSpec.describe Admin::EcosystemsController, speed: :slow, vcr: VCR_OPTS do
  let!(:admin) { FactoryGirl.create(:user, :administrator) }

  let!(:book_1) { FactoryGirl.create :content_book, title: 'Physics', version: '1' }
  let!(:ecosystem_1) { Content::Ecosystem.find(book_1.ecosystem.id) }
  let!(:book_2) { FactoryGirl.create :content_book, title: 'AP Biology', version: '2' }
  let!(:ecosystem_2) { Content::Ecosystem.find(book_2.ecosystem.id) }

  let!(:course) { CreateCourse.call(name: 'AP Biology').course }

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
    context 'tutor book' do
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
    end

    context 'cc book' do
      let!(:archive_url) { 'https://archive.cnx.org/contents/' }
      let!(:cnx_id) { 'f10533ca-f803-490d-b935-88899941197f@2.1' }

      it 'imports books and exercises as ecosystems' do
        expect {
          post :import, archive_url: archive_url, cnx_id: cnx_id
        }.to change { Content::Models::Book.count }.by(1)
        expect(flash[:notice]).to include 'Ecosystem import job queued.'
      end

      it 'imports a book even if the book already exists' do
        FactoryGirl.create(:content_book,
                           title: 'Derived copy of Biology',
                           url: "#{archive_url}#{cnx_id}",
                           version: '2.1')

        expect {
          post :import, archive_url: archive_url, cnx_id: cnx_id
        }.to change { Content::Models::Book.count }.by(1)
        expect(flash[:notice]).to include 'Ecosystem import job queued.'
      end

      it 'imports a book with a different version' do
        FactoryGirl.create(:content_book,
                           title: 'Derived copy of Biology',
                           url: "#{archive_url}#{cnx_id}",
                           version: '2.1')

        expect {
          post :import, archive_url: archive_url, cnx_id: cnx_id.sub('@2.1', '@1.1')
        }.to change { Content::Models::Book.count }.by(1)
        expect(flash[:notice]).to include 'Ecosystem import job queued.'
      end
    end
  end

  describe '#destroy' do
    it 'deletes an ecosystem' do
      expect {
        delete :destroy, id: ecosystem_1.id
      }.to change { Content::Models::Ecosystem.count }.by(-1)
      expect(flash[:notice]).to eq('Ecosystem deleted.')
      expect(flash[:error]).to be_nil
    end

    it 'returns an error if the ecosystem is linked to a course' do
      AddEcosystemToCourse.call(course: course, ecosystem: ecosystem_2)
      expect {
        delete :destroy, id: ecosystem_2.id
      }.to_not change { Content::Models::Ecosystem.count }
      expect(flash[:notice]).to be_nil
      expect(flash[:error]).to eq(
        'The ecosystem cannot be deleted because it is linked to a course')
    end
  end
end
